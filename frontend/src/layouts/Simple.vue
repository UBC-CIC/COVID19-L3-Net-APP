<template>
  <q-layout>
    <q-page-container>
      <!-- <q-banner class="ubc-color"><span class="text-h6">UBC AWS - Cloud Innovation Center</span>
      </q-banner>
      <q-banner v-if="!$q.platform.is.mobile" inline-actions class="bg-grey-3">This is a place to add some informatoin</q-banner> -->
      <q-space />
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script>
import { mapGetters } from "vuex";

export default {
  name: "default-layout",
  async beforeMount() {
    if (!this.hasIpAddress) {
      await this.$store.dispatch("profile/getIpAddress");
    }
  },
  computed: {
    ...mapGetters({
      isAuthenticated: "profile/isAuthenticated"
    })
  }
};
</script>

<style scoped>
.ubc-color {
  background-color: rgb(1, 33, 68);
  color: #fff
}
.error {
  background-color: red;
  color: #fff;
  word-wrap: break-word;
}
</style>