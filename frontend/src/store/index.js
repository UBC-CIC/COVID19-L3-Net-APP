import Vue from "vue";
import Vuex from "vuex";

import profile from "./profile";
//import file from "./file"

Vue.use(Vuex);

const modules = {
  profile,
//  file
};

const store = new Vuex.Store({ modules });

export default store;