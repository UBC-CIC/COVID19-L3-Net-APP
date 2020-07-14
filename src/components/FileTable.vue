<template>
  <div class="q-pa-md row items-start q-gutter-md">
    <q-markup-table style="max-width: 500px">
      <thead>
        <tr>
          <th class="text-left">File Name</th>
          <th class="text-left">Size</th>
          <th class="text-right"></th>
          <th class="text-right"></th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="val in listS3Files" v-bind:key="val.key">
          <td class="text-left">{{ val.key }}</td>
          <td class="text-left">{{ val.size }}</td>
          <td class="text-right">
            <q-btn color="red" icon="delete_outlined" @click="deleteFile(val.key)">
              <q-tooltip
                content-class="bg-black"
                content-style="font-size: 16px"
                :offset="[10, 10]"
              >Delete file</q-tooltip>
            </q-btn>
          </td>
          <td class="text-right">
            <router-link :to="{ name: 'predict', params: { code: val.key }}">
              <q-btn color="orange" icon="insert_chart_outlined">
                <q-tooltip
                  content-class="bg-black"
                  content-style="font-size: 16px"
                  :offset="[10, 10]"
                >Send to the ML model</q-tooltip>
              </q-btn>
            </router-link>
          </td>
        </tr>
      </tbody>
    </q-markup-table>
  </div>
</template>

<script type="text/javascript">
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
      uploadedFiles: {}
    };
  },
  props: {
    updateTigger: null
  },

  mounted() {
    this.listStorageFiles()
  },

  computed: {
    listS3Files() {
      const s3files = [];
      for (let i = 0; i < this.uploadedFiles.length; ++i) {
        if (this.uploadedFiles[i].key) {
          let size = prettySize(this.uploadedFiles[i].size);
          s3files.push({ key: this.uploadedFiles[i].key, size: size });
        }
      }
      return s3files;
    }
  },

  methods: {
    listStorageFiles() {
      Storage.list("", { level: "private" })
        .then(result => {
          this.uploadedFiles = result;
        })
        .catch(err => console.log(err));
    },

    deleteFile(fileName) {  
        Storage.remove(fileName, { level: 'private' })
            //.then(result => console.log(result))
            .catch(err => console.log(err));
        this.$emit('forceRenderFileTable');
    },
  }
};
</script>
