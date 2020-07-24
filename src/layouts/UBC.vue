<template>
<div>
  <head>
    <title>SapienML - COVID19-L3-Net Demo</title>

    <link
      rel="stylesheet"
      type="text/css"
      href="https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.4.1/semantic.min.css"
    />
    <link
      rel="stylesheet"
      type="text/css"
      href="https://tyleryasaka.github.io/semantic-ui-range/range.css"
    />
    <link rel="stylesheet" type="text/css" href="./sapiencoviddemo/sapiencovid_demo.css" />
    <link
      rel="stylesheet"
      type="text/css"
      href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.13.0/css/all.min.css"
    />
  </head>

  <router-view />
</div>
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
</style>