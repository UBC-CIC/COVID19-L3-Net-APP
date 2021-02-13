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
        <q-btn round color="deep-orange" icon="delete_outlined" @click="removeRows" />
        <q-space />
        <q-input borderless dense debounce="300" color="primary" v-model="filter">
          <template v-slot:append>
            <q-icon name="search" />
          </template>
        </q-input>
      </template>
      <!-- <template v-slot:body-cell-actions="props">
        <q-td :props="props">
          <q-btn
            dense
            round
            flat
            color="grey"
            @click="deleteFile(props.filename)"
            icon="delete_outlined"
          ></q-btn>
        </q-td>
      </template> -->

      <template v-slot:body-cell-v1="props">
        <q-td :props="props">
          <q-chip            
            :color="
              props.row.v1.code == '2'
                ? 'green'
                : props.row.v1.code == '3'
                ? 'red'
                : props.row.v1.code == '99'
                ? 'grey'
                : 'orange'
            "
            text-color="white"
            square
            :icon="
              props.row.v1.code == '2'
                ? 'check_circle'
                : props.row.v1.code == '3'
                ? 'error'
                : props.row.v1.code == '99'
                ? 'hide_source'
                : 'build_circle'
            "
            >
            <q-tooltip
              content-class="bg-black"
              content-style="font-size: 16px"
              :offset="[10, 10]"
              >{{ props.row.v1.msg }}</q-tooltip
            >
          </q-chip>
        </q-td>
      </template>

      <template v-slot:body-cell-v2="props">
        <q-td :props="props">
          <q-chip
            
            :color="
              props.row.v2.code == '2'
                ? 'green'
                : props.row.v2.code == '3'
                ? 'red'
                : 'orange'
            "
            text-color="white"
            square
            :icon="
              props.row.v2.code == '2'
                ? 'check_circle'
                : props.row.v2.code == '3'
                ? 'error'
                : 'build_circle'
            "
            >
            <q-tooltip
              content-class="bg-black"
              content-style="font-size: 16px"
              :offset="[10, 10]"
              >{{ props.row.v2.msg }}</q-tooltip
            >
          </q-chip>
        </q-td>
      </template>
    </q-table>
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
                  } else if ( status.versions[j].version == "v2") {
                    v2.code = status.versions[j].code;
                    v2.msg = status.versions[j].msg;
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

    deleteFile(fileName) {
      Storage.remove(fileName, { level: "private" })
        //.then(result => console.log(result))
        .catch((err) => console.log(err));
      this.$emit("forceRenderFileTable");
    },
  },
};
</script>
