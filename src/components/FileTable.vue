<template>
  <div class="q-pa-md">
    <q-table
      flat      
      :data="data"
      :columns="columns"
      row-key="fileuuid"
      virtual-scroll
      :rows-per-page-options="[0]"
      :visible-columns="visibleColumns"
      :selected-rows-label="getSelected"
      selection="multiple"
      :selected.sync="selected"
    >
      <template v-slot:top>
        <q-btn color="deep-orange" icon="delete_outline" @click="removeDialog" />
        <q-space />
        <!-- <q-input borderless dense debounce="300" color="primary" v-model="filter">
          <template v-slot:append>
            <q-icon name="search" />
          </template>
        </q-input> -->
      </template>

      <template v-slot:body-cell-v1="props">
        <ModelStatus :row="props.row.v1" />
      </template>
      <template v-slot:body-cell-v2="props">
        <ModelStatus :row="props.row.v2" />
      </template>

    </q-table>
     <q-dialog v-model="alert">
      <q-card>
        <q-card-section>
          <div class="text-h6">Alert</div>
        </q-card-section>

        <q-card-section class="q-pt-none">
          {{ alert_msg }}
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="OK" color="primary" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>

     <q-dialog v-model="confirm" persistent>
      <q-card>
        <q-card-section class="row items-center">
          <q-avatar icon="warning_amber" color="warning" text-color="white" />
          <span class="q-ml-sm">Are you sure to delete {{selected.length}} files?</span>
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="No" color="red" v-close-popup />
          <q-btn flat label="Yes" color="primary" v-close-popup @click="removeRows" />
        </q-card-actions>
      </q-card>
    </q-dialog>

  </div>
</template>

<script type="text/javascript">
import { mapState } from "vuex";
import axios from "axios";
import { Storage } from "aws-amplify";
import ModelStatus from "../components/ModelStatus";

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
    components: {
    ModelStatus
  },
  data() {
    return {
      selected: [],
      visibleColumns: ["filename", "size", "date", "actions", "v1", "v2"],
      columns: [
        {
          name: "filename",
          required: true,
          label: "File Name",
          align: "left",
          field: "key",
          sortable: true
        }, //key: filename, status: status, btn: btn, size: size, uploadat: uploadAt, code: code
        {
          name: "size",
          align: "center",
          label: "Size",
          field: "size",
          sortable: false,
        },
        {
          name: "date",
          align: "center",
          label: "Date",
          field: "date",
          sortable: true,
        },
        { name: "fileuuid", field: "fileuuid" },
        { name: "v1", label: "v1", field: "v1", align: "center" },
        { name: "v2", label: "v2", field: "v2", align: "center" },
        //{ name: "actions", label: "Actions", field: "", align: "center" },
      ],
      data: [],
      listFiles: {},
      alert: false,
      alert_msg: '',
      confirm: false
    };
  },
  props: {
    updateTigger: null,
  },

  mounted() {
    this.mountFilesTable();
  },

  computed: {
    ...mapState({
      user: (state) => state.profile.user,
    }),
  },

  methods: {
    getSelected () {
      return this.selected.length === 0 ? '' : `${this.selected.length} record${this.selected.length > 1 ? 's' : ''} selected of ${this.data.length}`
    },
    async mlview(fileuuid, filename) {
      let status = await this.getFileStatus(filename.replace(".zip",".status"));
      var url = status["cloudfrontUrl"] + "/html/" + fileuuid + "/index.html";
      //var win = window.open(url, '_blank');
      var win = window.open(url, "_self");
      win.focus();
    },
    async mountFilesTable() {
      try {
        this.data = [];
        let listFiles = await this.listStorageFiles();
        for (let i = 0; i < listFiles.length; ++i) {          
          if (listFiles[i].key) {
            let filename = listFiles[i].key;            
            if (
              filename.substring(filename.length - 3, filename.length) == "zip"
            ) {
              var filestatus = filename.replace(".zip",".status");               
              let status = await this.getFileStatus(filestatus);
              let v1 = {};
              let v2 = {};
              v1.code=99;
              v2.code=99;
              v1.msg="not submitted"
              v2.msg="not submitted"
              if (status.versions) {
                for (var j = 0; j < status.versions.length; j++) {
                  if (status.versions[j].version == "v1") {
                    v1.code = status.versions[j].code;
                    v1.msg = status.versions[j].msg;
                    v1.ver = "v1"
                    v1.url = status.cloudfrontUrl + "/html/v1/" + status.uid + "/index.html";
                  } else if ( status.versions[j].version == "v2") {
                    v2.code = status.versions[j].code;
                    v2.msg = status.versions[j].msg;
                    v2.ver = "v2";
                    v2.url = status.cloudfrontUrl + "/html/v2/" + status.uid + "/index.html";
                  }
                }
              }
              let uploadAt = this.$moment(listFiles[i].lastModified).format(
                "DD MMM HH:mm"
              );
              let size = prettySize(listFiles[i].size);
              let fileuuid =
                filename.substring(0, filename.length - 4) +
                "-" +
                this.$moment
                  .utc(listFiles[i].lastModified)
                  .format("YYYYMMDDHHmm");
              this.data.push({
                key: filename,
                v1: v1,
                v2: v2,
                size: size,
                date: uploadAt,
                fileuuid: fileuuid,
              });
            }
          }
        }
      } 
      catch(error) {
        console.log('error mountFilesTable: ', error);
      }
    },

    async getFileStatus(statusfile) {
      const statusUrl = await this.getFileStatusUrl(statusfile);
      const status = await this.readFileStatus(statusUrl);
      return status;
    },

    getFileStatusUrl(statusfile) {
      return Storage.get(statusfile, {
        level: "private",
        contentType: "application/json",
      });
    },

    readFileStatus(url) {
      return axios({
        url: url,
        method: "GET",
        responseType: "json",
      }).then((response) => response.data);
    },

    listStorageFiles() {      
      return Storage.list(
        "", { level: "private" }
        ).catch((err) => console.log(err));
    },

    removeDialog() {
      if (this.selected.length === 0) {
        this.alert_msg = "You have to select one or more files to be deleted."
        this.alert = true;
      }
      else {
        this.confirm = true
      }
    },

    async removeRows() {
      for (let i = 0; i < this.selected.length; ++i) {
        var statusfile = this.selected[i].key.replace("zip","status")
        var status  = await this.getFileStatus(statusfile)

        for (var j = 0; j < status.versions.length; j++) {
                   
            console.log("dcm/" + status.versions[j].version + "/" + status.uid + "/");

            Storage.remove("dcm/" + status.versions[j].version + "/" + status.uid + "/")
              //.then(result => console.log(result))
              .catch((err) => console.log(err));

            console.log("png/" + status.versions[j].version + "/" + status.uid + "/");
            Storage.remove("png/" + status.versions[j].version + "/" + status.uid + "/")
              //.then(result => console.log(result))
              .catch((err) => console.log(err));

            console.log("html/" + status.versions[j].version + "/" + status.uid + "/");
            Storage.remove("html/" + status.versions[j].version + "/" + status.uid + "/")
              //.then(result => console.log(result))
              .catch((err) => console.log(err));

            }

            console.log(this.selected[i].key);
            Storage.remove(this.selected[i].key, { level: "private" })
              //.then(result => console.log(result))
              .catch((err) => console.log(err));

            console.log(statusfile);
            Storage.remove(statusfile, { level: "private" })
              //.then(result => console.log(result))
              .catch((err) => console.log(err));

         this.$emit("forceRenderFileTable");
      }
    },
  },
};
</script>
