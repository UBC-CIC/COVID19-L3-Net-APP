/**
 * Profile [Vuex Module getter](https://vuex.vuejs.org/guide/getters.html) - isAuthenticated
 * @param {object} state - Profile state
 * @returns {boolean} - Whether current user is authenticated
 * @see {@link getSession} for more information on action that calls isAuthenticated
 */  

  export const hasSiegeData = state => {
    console.log("hasSiegeData: " + !!state.data);
    return !!state.data;
  };
    
