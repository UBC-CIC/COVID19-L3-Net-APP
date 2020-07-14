import { API, graphqlOperation } from "aws-amplify";
import { getSiegesByUserId, createSiege, updateSiege, deleleSiege } from "./graphql";

export async function siegeByUserId(
  { commit },
  { userId, paginationToken = "" }
) {
  console.log(paginationToken);
  try {
    console.group("store/siege/actions/getSiegesByUserId");
    commit("SET_LOADER", true);
    commit("SET_SIEGE", "");

    var nextToken = paginationToken || null;

    const {
      // @ts-ignore
      data: { siegeByUserId: siegeData, nextToken: paginationToken }
    } = await API.graphql(graphqlOperation(getSiegesByUserId, { userId: userId, nextToken: nextToken })
      );
    
    commit("SET_SIEGE", siegeData["items"]);
    commit("SET_SIEGE_PAGINATION", paginationToken);
    commit("SET_LOADER", false);
    console.groupEnd();
  } catch (error) {
    console.error(error);
    commit("SET_LOADER", false);
    throw error;
  }
}


export async function saveSiege({ commit },
  { id, name, code, desc, interval, timeZone, startDate, endDate, createdBy, createdAt, expireAt }) {
  try {
    console.group("store/siege/actions/saveSiege");
    commit("SET_LOADER", true);
    let result = "";

    if (id != null && id.length > 2) {
      const {
        // @ts-ignore
        data: { updateSiege: siegeId }
      } = await API.graphql(graphqlOperation(updateSiege, {
        id: id,
        name: name,
        desc: desc,
        code: code,
        interval: interval,
        timeZone: timeZone,
        startDate: startDate,
        endDate: endDate,
        createdBy: createdBy,
        createdAt: createdAt,
        expireAt: expireAt
      }));
      console.log(siegeId);
      result = `${siegeId}`
    } else {
      var d = new Date();
      const {
        // @ts-ignore
        data: { createSiege: siegeId }
      } = await API.graphql(graphqlOperation(createSiege, {
        name: name,
        desc: desc,
        code: d.getMilliseconds(),
        interval: interval,
        timeZone: timeZone,
        startDate: startDate,
        endDate: endDate,
        createdBy: createdBy,
        createdAt: createdAt,
        expireAt: expireAt
      }));
      console.log(siegeId);
      result = `${siegeId}`
    }

    commit("SET_LOADER", false);
    console.groupEnd();

    return result;
  } catch (error) {
    console.error(error);
    commit("SET_LOADER", false);
    throw error;
  }
}

export async function delSiege({ commit }, { id }) {
  try {
    console.group("store/calendar/actions/delSiege");
    console.log(id)
    commit("SET_LOADER", true);

    if (id != null && id.length > 2) {
      console.log("calling deleteSiege")
      const {
        // @ts-ignore
        data: { deleleSiege: slotId }
      } = await API.graphql(graphqlOperation(deleleSiege, { id: id }));
      console.log(slotId);
      commit("SET_LOADER", false);
      console.groupEnd();

      return slotId;
    } else {
      commit("SET_LOADER", false);
      console.groupEnd();
      throw "invalid Id";
    }
  } catch (error) {
    console.error(error);
    commit("SET_LOADER", false);
    throw error;
  }
}