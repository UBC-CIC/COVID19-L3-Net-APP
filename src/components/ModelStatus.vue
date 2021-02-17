<template>
  <q-td>
    <q-btn
      flat
      :color="
        row.code == '2'
          ? 'black'
          : row.code == '3'
          ? 'red'
          : 'orange'
      "
      size="lg"
      :icon="
        row.code == '2'
          ? 'analytics'
          : row.code == '3'
          ? 'error'
          : 'query_builder'
      "
      @click="showModel()"
    >
      <q-tooltip
        content-class="bg-black"
        content-style="font-size: 16px"
        :offset="[10, 10]"
        >{{ row.msg }}</q-tooltip
      >
    </q-btn>
  </q-td>
</template>

<script type="text/javascript">
import axios from "axios";
import { Storage } from "aws-amplify";

export default {
  name: "ModelStatus",
  props: ['row'],
  data() {
      return {
          urs: ''
      }      
  },
  methods: {
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

    showModel() {
        console.log(this.row.ver)
        console.log(this.row.code)
    }
  }
};

</script>