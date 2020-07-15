  export const getSiege = `query GetSiege($id: ID!) {
    getSiege(id: $id) {
      id
      name
      code
      desc
      timeZone
      startDate
      endDate
      interval
    }
  }
  `;

  export const siegeByCode = `query SiegeByCode($code: String) {
    siegeByCode(code: $code) {
      items {
        id
        name
        code
        desc
        timeZone
        startDate
        endDate
        interval
        expireAt
      }
    }
  }
  `;

  export const getSiegesByUserId = `query SiegeByUser($userId: ID!, $nextToken: String) {
    siegeByUserId(createdBy:$userId, nextToken: $nextToken) {
      items {
      	id
        name
        code
        desc
        timeZone
        startDate
        endDate
        interval        
      }
      nextToken
    }
  }`
  ;

  export const createSiege = `mutation CreateSiege(
    $name: String!
    $code: String!
    $timeZone: String!
    $startDate: AWSDate!
    $endDate: String!
    $interval: Int!
    $createdBy: ID!
    $desc: String
    $createdAt: AWSDate!
    $expireAt: Int
  ) {
    createSiege(input: {
      name: $name
      code: $code
      timeZone: $timeZone
      startDate: $startDate
      endDate: $endDate
      endDate: $endDate
      interval: $interval
      createdBy: $createdBy
      desc: $desc
      createdAt: $createdAt
      expireAt: $expireAt
    }) 
    {
      id
    }
  }
  `;

  export const updateSiege = `mutation UpdateSiege(
    $id: ID!
    $name: String!
    $code: String!
    $desc: String
    $timeZone: String!
    $startDate: AWSDate!
    $endDate: String!
    $interval: Int!
    $createdBy: ID!
    $createdAt: AWSDate!
    $expireAt: Int
  ) {
    updateSiege(input: {
      id: $id
      name: $name
      code: $code
      desc: $desc
      timeZone: $timeZone
      startDate: $startDate
      endDate: $endDate
      endDate: $endDate
      interval: $interval
      createdBy: $createdBy
      createdAt: $createdAt
      expireAt: $expireAt
    }) 
    {
      id
    }
  }
  `;

  export const deleleSiege = `mutation DeleteSiege($id: ID!) {
    deleteSiege(input: {
      id: $id
    }) 
    {
      id
    }
  }
  `;


