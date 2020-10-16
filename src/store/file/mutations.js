// @ts-nocheck
  export const SET_FILES= (state, data) => {
    state.files = data;
  };

  export const SET_LOADER = (state, isLoading) => {
    state.loading = isLoading;
  };
  
  export const SET_FILE_PAGINATION = (state, paginationToken) => {
    state.paginationToken = paginationToken;
  };