/* eslint-disable */
// this is an auto generated file. This will be overwritten

export const createAppFile = /* GraphQL */ `
  mutation CreateAppFile(
    $input: CreateAppFileInput!
    $condition: ModelAppFileConditionInput
  ) {
    createAppFile(input: $input, condition: $condition) {
      id
      ctName
      ctSize
      ctCreatedAt
      status
      expireAt
      resultName
      resultSize
      resultCreatedAt
      createdAt
      updatedAt
    }
  }
`;
export const updateAppFile = /* GraphQL */ `
  mutation UpdateAppFile(
    $input: UpdateAppFileInput!
    $condition: ModelAppFileConditionInput
  ) {
    updateAppFile(input: $input, condition: $condition) {
      id
      ctName
      ctSize
      ctCreatedAt
      status
      expireAt
      resultName
      resultSize
      resultCreatedAt
      createdAt
      updatedAt
    }
  }
`;
export const deleteAppFile = /* GraphQL */ `
  mutation DeleteAppFile(
    $input: DeleteAppFileInput!
    $condition: ModelAppFileConditionInput
  ) {
    deleteAppFile(input: $input, condition: $condition) {
      id
      ctName
      ctSize
      ctCreatedAt
      status
      expireAt
      resultName
      resultSize
      resultCreatedAt
      createdAt
      updatedAt
    }
  }
`;
