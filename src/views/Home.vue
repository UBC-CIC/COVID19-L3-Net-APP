<template>
  <div class="q-pa-md row items-start q-gutter-md">
    <div class="row">
      <div class="col-8">
        <q-card class="upload-card">
          <q-card-section class="ubc-color">
            <div class="text-h6">Upload CT Scans</div>
            <div class="text-subtitle2">
              At this step the CT Scan will be saved into a temporarily storage due to its size. After uploading it you will be able to send it to be processed by the model.
              <span
                class="text-bold"
              >The files will be deleted after 7 days</span>
            </div>
          </q-card-section>

          <q-separator />

          <q-card-section>
            <div class="q-gutter-sm">
              <div class="text-subtitle2">
                Please select the ML model version to process the uploaded files. 
              </div>
              <q-checkbox v-model="mlversion" val="v1" label="v1" />
              <q-checkbox v-model="mlversion" val="v2" label="v2 (latest)" />
            </div>
          </q-card-section>

          <q-card-actions>
            <q-file
              id="qfile"
              style="max-width: 450px"
              max-files="50"
              v-model="files"
              @input="updateFiles"
              outlined
              label="CTScans (zip only)"
              multiple
              :clearable="!isUploading"
              :filter="checkFileType"
              @rejected="onRejected"
            >
              <template v-slot:file="{ index, file }">
                <q-chip
                  class="full-width q-my-xs"
                  :removable="isUploading && uploadProgress[index].percent < 1"
                  square
                  @remove="cancelFile(index)"
                >
                  <q-linear-progress
                    class="absolute-full full-height"
                    :value="uploadProgress[index].percent"
                    :color="uploadProgress[index].color"
                    track-color="grey-2"
                  ></q-linear-progress>

                  <q-avatar>
                    <q-icon :name="uploadProgress[index].icon"></q-icon>
                  </q-avatar>

                  <div class="ellipsis relative-position">{{ file.name }}</div>

                  <q-tooltip>{{ file.name }}</q-tooltip>
                </q-chip>
              </template>

              <template v-slot:after v-if="canUpload">
                <q-btn
                  class="ubc-color"
                  icon="arrow_circle_up"
                  @click="upload"
                  :disable="!canUpload"
                  :loading="isUploading"
                  label="Upload"
                ></q-btn>
              </template>
            </q-file>
          </q-card-actions>

          <q-separator inset />

          <q-card-section><span class="text-body1">After all the files have been successfully uploaded you can move to the next step</span></q-card-section>
        </q-card>
      </div>
      </div>
      
      <div class="row">
        <q-card class="my-card">
          <q-item class="ubc-color"> 
            <q-item-section>
              <q-item-label>
                <q-icon name="account_box"  style="font-size: 32px;" /> {{ email }}
                <q-btn align="right" color="orange" size="lg" flat round dense icon="exit_to_app" @click="signOut"> 
                <q-tooltip
                  content-class="bg-black"
                  content-style="font-size: 16px"
                  :offset="[10, 10]"
                >Sign Out</q-tooltip>
                </q-btn>
              </q-item-label>
             </q-item-section>
          </q-item>
          <q-separator />
          <q-card-section>
            <div class="text-h6">
              Files submitted
              <span class></span>
            </div>
            <div class="text-subtitle2">
              <span class="text-body1"> 
                <q-btn flat round color="primary" icon="refresh"  @click="forceRenderFileTable"/></span> 
                Please, click on the refresh button to update the status
            </div>
          </q-card-section>

          <q-separator />
          <q-card-actions vertical>
            <FileTable :key="updateTigger" @forceRenderFileTable="forceRenderFileTable" />
          </q-card-actions>           
        </q-card>
      </div>
  </div>
</template>

<script type="text/javascript">
import { mapState, mapGetters } from "vuex";
import { Auth } from 'aws-amplify';
import { Storage } from "aws-amplify";
import FileTable from "../components/FileTable";

export default {
  name: "Home",
  components: {
    FileTable
  },
  data() {
    return {
      filesMaxSize: null,
      files: null,
      uploadProgress: [],
      uploading: null,
      //max_upload_size: process.env.VUE_APP_MAX_UPLOAD_SIZE_BYTES,
      updateTigger: 0,
      mlversion: [ "v2" ]
    };
  },

  computed: {
    ...mapState({
      user: state => state.profile.user
    }),
    ...mapGetters({
      isAuthenticated: "profile/isAuthenticated",
      email: "profile/email"
    }),
    isUploading() {
      return this.uploading !== null;
    },

    canUpload() {
      if (( this.files !== null) && (this.mlversion.length != 0)) {
        return true;
      }
      else {
        return false;
      }
    }
  },

  methods: {
    async signOut() {
      try {
          await Auth.signOut();
          this.$router.push("/auth");
      } catch (error) {
          console.log('error signing out: ', error);
      }
    },
    cancelFile(index) {
      this.uploadProgress[index] = {
        ...this.uploadProgress[index],
        error: true,
        color: "orange-2"
      };
    },

    updateFiles(files) {
      this.files = files;
      this.uploadProgress = (files || []).map(file => ({
        error: false,
        color: "green-2",
        percent: 0,
        file: file,
        icon: "insert_drive_file"
      }));
    },

    upload() {
      var versions = this.mlversion;
      this.uploadProgress.forEach(f => {
        if (f.file.size === 0) {
          return;
        }

        const reader = new FileReader();
        var vm = this;

        reader.onload = function(event) {   
          
          //Saving .status
          var statusObj = {};          
          statusObj.cloudfrontUrl = "";
          statusObj.versions = []       
          for (var i = 0; i < versions.length; i++) {
            statusObj.versions.push({
              code: 0,
              msg: "Sent to validation",
              version: versions[i]
            })
          }

          var jsonString= JSON.stringify(statusObj);

          var statusFilename = f.file.name.toLowerCase().replace(".zip",".status");
          Storage.put(
          statusFilename, jsonString,
            {
              level: "private",
              contentType: "application/json"
            }
          ).catch(error => console.log(error));
          
          //Saving ZIP file      
          var contents = event.target.result;
          Storage.put(f.file.name.toLowerCase(), contents, {
            level: "private",
            contentType: "application/zip",
            progressCallback(progress) {
              //console.log(`Uploaded: ${progress.loaded}/${progress.total}`);
              f.percent = progress.loaded / progress.total;
            }
          })
            .then(result => {
              vm.forceRenderFileTable();
              vm.$q.notify({
                color: "primary",
                position: "top",
                icon: "done",
                message: "File uploaded successfully: " + result.key
              });

            })
            .catch(err => console.log(err));
        };

        reader.onerror = function(event) {
          console.error(
            "File could not be read! Code " + event.target.error.code
          );
        };
        reader.readAsArrayBuffer(f.file);
      });
    },

    forceRenderFileTable() {
      this.updateTigger += 1;
    },

    checkFileSize(files) {
      return files.filter(
        file => file.size < process.env.VUE_APP_MAX_UPLOAD_SIZE_BYTES
      );
    },

    checkFileType(files) {
      return files.filter(file => file.type === "application/zip");
    },

    onRejected(rejectedEntries) {
      // Notify plugin needs to be installed
      // https://quasar.dev/quasar-plugins/notify#Installation
      this.$q.notify({
        type: "negative",
        message: `${rejectedEntries.length} file(s) did not pass validation constraints`
      });
    },
    getHostUrl(value) {
      return (
        window.location.protocol +
        "//" +
        window.location.hostname +
        "/#/" +
        value +
        "/"
      );
    }
  }
};
</script>

<style scoped>
.ubc-color {
  background-color: rgb(1, 33, 68);
  color: #fff;
}
.error {
  background-color: red;
  color: #fff;
  word-wrap: break-word;
}
.q-data-table td,
.q-data-table th {
  /* don't shorten cell contents */
  white-space: normal !important;
}
</style>