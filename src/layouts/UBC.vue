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
  },
  methods: {
    async loadScriptHead(url){
    var script = document.createElement("script")
    script.type = "text/javascript";
    script.src = url;
    document.head.appendChild(script)
}
  },
  mounted() {
    this.loadScriptHead("https://d2o8vcf7ix9uyt.cloudfront.net/sapien/three.min.js");
    this.loadScriptHead("https://code.jquery.com/jquery-1.11.1.min.js");
    this.loadScriptHead("https://d2o8vcf7ix9uyt.cloudfront.net/sapien/ami.min.js");
    this.loadScriptHead("https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.4.1/semantic.min.js");
    this.loadScriptHead("https://tyleryasaka.github.io/semantic-ui-range/range.js");
  }
};
</script>

<style>
@import "https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.4.1/semantic.min.css";
@import "https://tyleryasaka.github.io/semantic-ui-range/range.css";
@import "https://d2o8vcf7ix9uyt.cloudfront.net/sapien/sapiencovid_demo.css";
@import "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.13.0/css/all.min.css";
</style>