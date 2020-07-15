/* eslint-disable */
// this is an auto generated file. This will be overwritten

export const getAppFile = /* GraphQL */ `
  query GetAppFile($id: ID!) {
    getAppFile(id: $id) {
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
export const listAppFiles = /* GraphQL */ `
  query ListAppFiles(
    $filter: ModelAppFileFilterInput
    $limit: Int
    $nextToken: String
  ) {
    listAppFiles(filter: $filter, limit: $limit, nextToken: $nextToken) {
      items {
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
      nextToken
    }
  }
`;
export const byName = /* GraphQL */ `
  query ByName(
    $ctName: String
    $status: ModelStringKeyConditionInput
    $sortDirection: ModelSortDirection
    $filter: ModelAppFileFilterInput
    $limit: Int
    $nextToken: String
  ) {
    ByName(
      ctName: $ctName
      status: $status
      sortDirection: $sortDirection
      filter: $filter
      limit: $limit
      nextToken: $nextToken
    ) {
      items {
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
      nextToken
    }
  }
`;
