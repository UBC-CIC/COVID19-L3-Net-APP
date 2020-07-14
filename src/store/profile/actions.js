import { Auth } from "aws-amplify";
import axios from 'axios'

export async function getSession({ commit, getters }) {
  console.group("store/profile/actions/getSession");
  console.log("Fetching current session");
  try {
    const user = await Auth.currentAuthenticatedUser();
    if (!getters.isAuthenticated) {
      commit("SET_USER", user);
      console.groupEnd();
    }
  } catch (err) {
    console.log(err);
    if (getters.isAuthenticated) {
      commit("SET_USER");
      console.groupEnd();
    }
    throw new Error(err);
  }
}

export async function getIpAddress({ commit }) {  
    console.log("profile/getIpAddress");
    await axios.get('https://api.ipify.org?format=json').then((x) => { 
      commit("SET_CLIENT_IP", x.data["ip"]);         
    }).catch((error) => {
      console.error(error);
      commit("SET_CLIENT_IP", "ERROR_IP");
    });
}