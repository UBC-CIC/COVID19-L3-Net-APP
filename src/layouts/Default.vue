<template>
  <q-layout>
    <q-header elevated class="ubc-color">
      <q-toolbar>
        <q-toolbar-title :padding="1">UBC AWS - Cloud Innovation Center</q-toolbar-title>
        <q-btn flat round dense icon="portrait" :label="email" />
        <q-btn color="orange" flat round dense icon="exit_to_app" @click="signOut" />
      </q-toolbar>
    </q-header>
    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script>
import { mapGetters } from "vuex";
import { Auth } from 'aws-amplify';

export default {
  name: "default-layout",
  async beforeMount() {
    if (!this.hasIpAddress) {
      await this.$store.dispatch("profile/getIpAddress");
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
    }
  },
  computed: {
    ...mapGetters({
      isAuthenticated: "profile/isAuthenticated",
      email: "profile/email"
    })
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
</style>
