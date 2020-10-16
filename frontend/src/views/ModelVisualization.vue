<template>
  <div id="visualizer">
    <div id="header"></div>
    <div id="r1" class="renderer">
      <div class="r1-info" id="r1-info-topleft"></div>
      <div class="r1-info" id="r1-info-bottomleft"></div>
      <div class="r1-info" id="r1-info-topright"></div>
      <div class="r1-info" id="r1-info-bottomright"></div>

      <!-- <div id="loaderdiv" class="ui active dimmer">
        <div class="ui text loader">Loading</div>
      </div>-->
    </div>
    <div id="aistats-container">
      <div id="instructions" class="ui segment vertical"></div>

      <div class="ui segment vertical">
        <div class="ui grid">
          <div class="row">
            <button class="ui button" id="btn3d">
              <i class="fas fa-cube"></i> View 3D Rendering
            </button>
          </div>
          <div class="row">
            <div class="five wide column">
              <label>Overlay</label>
            </div>
            <div class="eleven wide column">
              <div class="ui toggle checkbox">
                <input type="checkbox" id="toggle_overlay" checked />
                <label></label>
              </div>
            </div>
          </div>
          <div class="row">
            <div class="five wide column">
              <label>Overlay Opacity</label>
            </div>
            <div class="eleven wide column">
              <div style="display:inline-block;" class="ui range" id="range-opacity"></div>
            </div>
          </div>
          <div class="row">
            <div class="five wide column">
              <label>Slice</label>
            </div>
            <div class="eleven wide column">
              <div style="display:inline-block;" class="ui range" id="range-slice"></div>
            </div>
          </div>
          <div class="row">
            <div class="five wide column">
              <label>Window Level</label>
            </div>
            <div class="eleven wide column">
              <div style="display:inline-block;" class="ui range" id="range-wl"></div>
            </div>
          </div>
          <div class="row">
            <div class="five wide column">
              <label>Window Width</label>
            </div>
            <div class="eleven wide column">
              <div style="display:inline-block;" class="ui range" id="range-ww"></div>
            </div>
          </div>
        </div>
      </div>
      <div class="ui segment vertical">
        <h1>AI Statistics</h1>

        <div class="ai-statistics">
          <p>
            Lung Volume (L):
            <span id="lungLiters">L</span>
            <br />Lung Involvement (L):
            <span id="affectedLiters">L</span>
            <br />Percentage of Lung Involvement (%):
            <span id="affectedPerc">%</span>
            <br />Percentage of Well-Aerated-Lung (%):
            <span id="unaffectedPerc">%</span>
            <br />Classification:
            <span id="classification"></span>
          </p>
        </div>
      </div>
      <div class="ui segment vertical">
        <H1>Legend</H1>

        <div id="legend">
          <div class="legendEntry" style="background:#FF0800;"></div>
          <label>
            (
            <span id="GGstat">%</span>) Pure Ground Glass
          </label>

          <div class="legendEntry" style="background:#FF662B;"></div>
          <label>
            (
            <span id="GGOstat">%</span>) GGO w/ Smooth Interlobular Thickening, GGO w/ Crazy Paving
          </label>

          <div class="legendEntry" style="background:#8D02FF;"></div>
          <label>
            (
            <span id="ConsolidationStat">%</span>) Organizing Pneumonia, Atoll Sign, Consolidation
          </label>
        </div>
      </div>
      <div class="ui segment vertical">
        <div id="acknowledgments">
          <p>
            Powered by:
            <a href="https://cic.ubc.ca/">UBC-CIC</a>,
            <a href="https://www.vchri.ca/">VCHRI</a>,
            <a href="https://aws.amazon.com/">AWS</a>,
            <a href="https://www.sapienml.com/">SapienML</a>,
            <a href="https://xtract.ai/">xtract.ai</a>, and
            <a href="https://www.elementai.com/">Element AI</a>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "ModelVisualization",
  data() {
    return {
      filePath: this.$route.params.code,
      dataPath:
        "https://d2o8vcf7ix9uyt.cloudfront.net/png/" +
        this.$route.params.code +
        "/data.js"
    };
  },
  methods: {
    async loadScriptX(url, id) {
      var script = document.createElement("script");
      script.type = "x-shader/x-fragment";
      script.src = url;
      script.id = id;
      document.body.appendChild(script);
    },
    async loadScript(url) {
      var script = document.createElement("script");
      script.type = "text/javascript";
      script.src = url;
      document.head.appendChild(script);
    }
  },
  mounted() {
    this.loadScriptX(
      "https://d2o8vcf7ix9uyt.cloudfront.net/sapien/fragmentShaderFirstPass.js",
      "fragmentShaderFirstPass"
    );
    this.loadScriptX(
      "https://d2o8vcf7ix9uyt.cloudfront.net/sapien/vertexShaderFirstPass.js",
      "vertexShaderFirstPass"
    );
    this.loadScriptX(
      "https://d2o8vcf7ix9uyt.cloudfront.net/sapien/fragmentShaderSecondPass.js",
      "fragmentShaderSecondPass"
    );
    this.loadScriptX(
      "https://d2o8vcf7ix9uyt.cloudfront.net/sapien/vertexShaderSecondPass.js",
      "vertexShaderSecondPass"
    );

    this.loadScript(this.dataPath);
    this.loadScript(
      "https://d2o8vcf7ix9uyt.cloudfront.net/sapien/sapiencovid_demo.js"
    );
  }
};
</script>