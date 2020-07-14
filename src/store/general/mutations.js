// @ts-nocheck
  export const SET_SIEGE= (state, data) => {
    state.data = data;
  };

  export const SET_LOADER = (state, isLoading) => {
    state.loading = isLoading;
  };
  
  export const SET_SIEGE_PAGINATION = (state, paginationToken) => {
    state.paginationToken = paginationToken;
  };