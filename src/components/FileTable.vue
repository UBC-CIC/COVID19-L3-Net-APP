<template>
  <div class="q-pa-md row items-start q-gutter-md">
    <q-markup-table>
      <thead>
        <tr>
          <th class="text-right"><q-btn flat color="black" icon="delete_outlined" /></th>
          <th class="text-left">File Name</th>
          <th class="text-center">Size</th>
          <th class="text-center">Date</th>
          <th class="text-center">Status</th>          
          <th class="text-right"><q-btn flat color="black" icon="insert_chart_outlined" /></th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="val in filesTable" v-bind:key="val.key">
          <td class="text-right">
            <q-btn flat color="red" icon="delete_outlined" @click="deleteFile(val.key)">
              <q-tooltip
                content-class="bg-black"
                content-style="font-size: 16px"
                :offset="[10, 10]"
              >Delete file</q-tooltip>
            </q-btn>
          </td>
          <td class="text-left">{{ val.key }}</td>
          <td class="text-left">{{ val.size }}</td>
          <td class="text-center">{{ val.uploadat }}</td>
          <td class="text-center">
            <q-btn flat :color="val.btn.color" :icon="val.btn.icon">
              <q-tooltip
                content-class="bg-black"
                content-style="font-size: 16px"
                :offset="[10, 10]"
              >{{ val.status["msg"] }}</q-tooltip>
            </q-btn></td>          
          <td class="text-center">           
              <q-btn v-if="val.status['code'] == 2" flat color="black" icon="insert_chart_outlined" @click="mlview(val.code)">
                <q-tooltip
                  content-class="bg-black"
                  content-style="font-size: 16px"
                  :offset="[10, 10]"
                >Visualize ML model</q-tooltip>
              </q-btn>
            <!-- <router-link :to="{ name: 'visualize', params: { code: val.code }}">              
              <q-btn v-if="val.status['code'] == 2" flat color="black" icon="insert_chart_outlined">
                <q-tooltip
                  content-class="bg-black"
                  content-style="font-size: 16px"
                  :offset="[10, 10]"
                >Visualize ML model</q-tooltip>
              </q-btn>
            </router-link> -->
          </td>
        </tr>
      </tbody>
    </q-markup-table>
  </div>
</template>

<script type="text/javascript">
import { mapState } from "vuex";
import axios from "axios";
import { Storage } from "aws-amplify";

function prettySize(bytes, separator = "", postFix = "") {
  if (bytes) {
    const sizes = ["Bytes", "KB", "MB", "GB", "TB"];
    const i = Math.min(
      parseInt(Math.floor(Math.log(bytes) / Math.log(1024)), 10),
      sizes.length - 1
    );
    return `${(bytes / 1024 ** i).toFixed(i ? 1 : 0)}${separator}${
      sizes[i]
    }${postFix}`;
  }
  return "n/a";
}

export default {
  name: "Home",
  data() {
    return {
      filesTable: [],
      listFiles: {}
    };
  },
  props: {
    updateTigger: null
  },

  mounted() {
    this.mountFilesTable()
  },

  computed: {
    ...mapState({
      user: state => state.profile.user,
    }),
    
  },

  methods: {
    mlview(code) {
      var url = process.env.VUE_APP_CLOUDFRONT_URL + '/html/' + code + '/index.html';
      //var win = window.open(url, '_blank');
      var win = window.open(url, '_self');
      win.focus();      
    },
    async mountFilesTable() {
      this.filesTable = [];      
      let listFiles = await this.listStorageFiles();
      for (let i = 0; i < listFiles.length; ++i) {
        if (listFiles[i].key) {
          let filename = listFiles[i].key          
          if (filename.substring(filename.length - 3, filename.length) == "zip") {            
            let status = await this.getFileStatus(filename + ".status")
            let btn = {}
            if (status["code"] == 0) {
              btn.color = "orange"
              btn.icon = "query_builder"
            } else if (status["code"] == 1) {
              btn.color = "orange"
              btn.icon = "build_circle"
            } else if (status["code"] == 2) {
              btn.color = "green"
              btn.icon = "check_circle"            
            } else if (status["code"] == 3) {
              btn.color = "red"
              btn.icon = "error"
            } else {
              btn.color = "red"
              btn.icon = "help"
            }
            let uploadAt = this.$moment(listFiles[i].lastModified).format('DD MMM HH:mm')
            let size = prettySize(listFiles[i].size);
            let code = filename.substring(0, filename.length - 4) + '-' + this.$moment.utc(listFiles[i].lastModified).format("YYYYMMDDHHmm")
            this.filesTable.push({ key: filename, status: status, btn: btn, size: size, uploadat: uploadAt, code: code });            
          }
        }
      }
    },

    async getFileStatus(filename) {
      const statusUrl = await this.getFileStatusUrl(filename);      
      const status = await this.readFileStatus(statusUrl);
      return status;
    },

    getFileStatusUrl(filename) {
      return Storage.get(filename, { 
        level: "private",
        contentType: "application/json",
      });
    },

    readFileStatus(url) {
      return axios({
          url: url,
          method: "GET",
          responseType: "json"
        }).then(response => response.data) 
    },

    listStorageFiles() {
      return Storage.list("", { level: "private" });
    },

    deleteFile(fileName) {  
        Storage.remove(fileName, { level: 'private' })
            //.then(result => console.log(result))
            .catch(err => console.log(err));
        this.$emit('forceRenderFileTable');
    }
  }
};
</script>
