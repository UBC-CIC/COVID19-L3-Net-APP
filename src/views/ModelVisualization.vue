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
      </div> -->
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

<script id="fragmentShaderFirstPass" type="x-shader/x-fragment" src="./sapiencoviddemo/fragmentShaderFirstPass.js"></script>
<script id="vertexShaderFirstPass" type="x-shader/x-vertex" src="./sapiencoviddemo/vertexShaderFirstPass.js"></script>
<script id="fragmentShaderSecondPass" type="x-shader/x-fragment" src="./sapiencoviddemo/fragmentShaderSecondPass.js"></script>
<script id="vertexShaderSecondPass" type="x-shader/x-vertex" src="./sapiencoviddemo/vertexShaderSecondPass.js"></script>

<script type="text/javascript" :src="dataPath" ></script>
<script type="text/javascript" src="./sapiencoviddemo/sapiencovid_demo.js"></script>

<script>
export default {
  name: "ModelVisualization",
  data() {
    return {
      filePath: this.$route.params.code,
      dataPath: "https://d2o8vcf7ix9uyt.cloudfront.net/png/" + this.$route.params.code + "/data.js"
    };
  },
  mounted() {

      let script1 = document.createElement('script');
      script1.type = 'text/javascript';
      script1.src = 'https://d2o8vcf7ix9uyt.cloudfront.net/sapien/three.min.js';      
      //script1.setAttribute('src', './sapiencoviddemo/three.min.js');
      document.head.appendChild(script1);

      let script2 = document.createElement('script');
      script2.setAttribute('src', 'https://code.jquery.com/jquery-1.11.1.min.js');
      document.head.appendChild(script2);

      let script3 = document.createElement('script');
      script3.setAttribute('src', 'https://d2o8vcf7ix9uyt.cloudfront.net/sapien/ami.min.js');
      document.head.appendChild(script3);

      let script4 = document.createElement('script')
      script4.setAttribute('src', 'https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.4.1/semantic.min.js');
      document.head.appendChild(script4);

      let script5 = document.createElement('script');
      script5.setAttribute('src', 'https://tyleryasaka.github.io/semantic-ui-range/range.js');
      document.head.appendChild(script5);

      let script6 = document.createElement('script');
      script6.setAttribute('src', 'https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.4.1/semantic.min.js');
      document.head.appendChild(script6);

      let script7 = document.createElement('script');
      script7.setAttribute('src', 'https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.4.1/semantic.min.js');
      document.head.appendChild(script7);
  }
};
</script>

<style>
    @import "https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.4.1/semantic.min.css";
	@import "https://tyleryasaka.github.io/semantic-ui-range/range.css";
	@import "https://d2o8vcf7ix9uyt.cloudfront.net/sapien/sapiencovid_demo.css";
	@import "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.13.0/css/all.min.css";
</style>