<template>
  <div class="q-pa-md">
    <q-card square class="shadow-24">
      <q-card-section>
        <div class="text-h6">Processing data</div>
        <div class="text-subtitle2">In this phase we send the CT-Scans to the model an save the results. If it executed succefully you should be able to see visualize the model result at the end of the process. For a more comprenhensive analysis please access xxxxxx</div>
        <q-item v-if="apiError">
          <q-banner class="text-white bg-red">{{ apiErrorMsg }}</q-banner>
        </q-item>
        <q-item v-if="s3Error">
          <q-banner class="text-white bg-red">{{ s3ErrorMsg }}</q-banner>
        </q-item>
      </q-card-section>
      <q-card-section>
        <q-linear-progress :value="apiProgress" size="15px" class="q-mt-md" />
        <q-item-label text-subtitle1>Sending to the Machine Learning model</q-item-label>
        <q-icon name="highlight_off" class="text-red" style="font-size: 2em;" v-if="apiError" />
        <q-icon
          name="check_circle_outline"
          class="text-teal"
          style="font-size: 2em;"
          v-if="isApiFinished"
        />
        
        <q-separator  />

        <q-linear-progress :value="s3Progress" size="15px" class="q-mt-md" />
        <q-item-label text-subtitle1>Saving Results</q-item-label>
        <q-icon
          name="check_circle_outline"
          class="text-teal"
          style="font-size: 2em;"
          v-if="isS3Saved"
        />
        
      </q-card-section>
    </q-card>

<div>
    <q-card square class="shadow-24">
      <q-card-section>
        <canvas id="canvas" />
      </q-card-section>
    </q-card>
</div>
  </div>
</template>

<script>
import { Storage } from "aws-amplify";
import axios from "axios";
import Tiff from "tiff.js"

export default {
  name: "Predict",
  data() {
    return {
      fileName: this.$route.params.code,
      s3Url: null,
      blob: null,
      tiffUrl: null,
      s3Progress: 0,
      apiProgress: 0,
      isApiFinished: false,
      isS3Saved: false,
      apiError: false,
      s3Error: false,
      s3ErrorMsg: null,
      apiErrorMsg: null
    };
  },
  beforeMount() {
    this.callPrediction();
  },
  mounted() {
    this.interval = setInterval(() => {
      if (this.isApiFinished) {
        this.apiProgress = 1;
        return;
      }

      if (this.apiError) {
        this.apiProgress = 1;
        return
      }

      if (this.apiProgress >= 1) {
        this.errorMsg = "Something went wrong with the API call!";
        return;
      }

      this.apiProgress = this.apiProgress + 0.025;
    }, 1000);
  },

  methods: {

    renderTiff() {
      var canvas = document.getElementById("canvas");
      axios.get(this.tiffUrl, {responseType: "blob", timeout: 30000})
        .then(response => {
          console.log(response)
          var blob = new Blob([response.data], { type: "image/tiff" });
          var tiff = new Tiff({buffer: blob});
          var width = tiff.width();
          var height = tiff.height();
          canvas = tiff.toCanvas();
        if (canvas) {
          canvas.setAttribute('style', 'width:' + (width*0.3) +
            'px; height: ' + (height*0.3) + 'px');
        }
        })
        .catch(function(error) {
          console.log(error);
        });
    },


    callPrediction() {
      const _this = this;
      Storage.get(this.fileName, { level: "private" })
        .then(result => {
          _this.s3Url = escape(result);
          axios
            .get(
              process.env.VUE_APP_PREDICT_URL +
                "?input_file=" +
                _this.s3Url +
                "&format=tiff"
            )
            .then(function(response) {
              console.log(response)
              _this.isApiFinished = true;
              _this.saveResult(response.data);
            })
            .catch(function(error) {
              console.log(error);
              _this.apiErrorMsg = error;
              _this.apiError = true;
            });
        })
        .catch(err => {
          console.log(err);
          this.apiErrorMsg = err;
          _this.apiError = true;
        });
    },

    saveResult(contents) {
      console.log("saving into S3");
      var _this = this;
      Storage.put(this.fileName.replace(/\.[^/.]+$/, "") + "-result.tiff", contents, {
        level: "private",
        contentType: "image/tiff",
        progressCallback(progress) {
          _this.s3Progress = progress.loaded / progress.total;
        }
      }).then(result => {
        _this.isS3Saved = true;
        Storage.get(result.key, { level: "private" })
          .then(response => {
            _this.tiffUrl = response;
            _this.renderTiff()
          })
          .catch(err => {
            console.log(err);
            _this.s3Error = true,
            _this.s3ErrorMsg = err;
          });
      });
    },

    downloadFile() {
      console.log(this.s3Url);
      axios({
        url: this.s3Url,
        method: "GET",
        responseType: "blob"
      })
        .then(response => {
          //console.log(response.data)
          this.blob = new Blob([response.data], { type: "application/zip" });
        })
        .catch(function(error) {
          console.log(error);
        });
    }
  },

  compute: {}
};
</script>

<style scoped>
</style>