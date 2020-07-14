import Vue from "vue";
import Vuex from "vuex";

import profile from "./profile";
//import general from "./general"

Vue.use(Vuex);

const modules = {
  profile
};

const store = new Vuex.Store({ modules });

export default store;