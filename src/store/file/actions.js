import { API, graphqlOperation } from "aws-amplify";
import { getfilesByUserId, createfile, updatefile, delelefile } from "./graphql";

export async function listFiles(
  { commit },
  { paginationToken = "" }
) {
  console.log(paginationToken);
  try {
    console.group("store/file/actions/listFiles");
    commit("SET_LOADER", true);
    commit("SET_FILES", "");

    var nextToken = paginationToken || null;

    const {
      // @ts-ignore
      data: { listFiles: filesData, nextToken: paginationToken }
    } = await API.graphql(graphqlOperation(getfilesByUserId, { nextToken: nextToken })
      );
    
    commit("SET_FILE", filesData["items"]);
    commit("SET_FILE_PAGINATION", paginationToken);
    commit("SET_LOADER", false);
    console.groupEnd();
  } catch (error) {
    console.error(error);
    commit("SET_LOADER", false);
    throw error;
  }
}


export async function savefile({ commit },
  { id, name, code, desc, interval, timeZone, startDate, endDate, createdBy, createdAt, expireAt }) {
  try {
    console.group("store/file/actions/savefile");
    commit("SET_LOADER", true);
    let result = "";

    if (id != null && id.length > 2) {
      const {
        // @ts-ignore
        data: { updatefile: fileId }
      } = await API.graphql(graphqlOperation(updatefile, {
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
      console.log(fileId);
      result = `${fileId}`
    } else {
      var d = new Date();
      const {
        // @ts-ignore
        data: { createfile: fileId }
      } = await API.graphql(graphqlOperation(createfile, {
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
      console.log(fileId);
      result = `${fileId}`
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

export async function delfile({ commit }, { id }) {
  try {
    console.group("store/calendar/actions/delfile");
    console.log(id)
    commit("SET_LOADER", true);

    if (id != null && id.length > 2) {
      console.log("calling deletefile")
      const {
        // @ts-ignore
        data: { delelefile: slotId }
      } = await API.graphql(graphqlOperation(delelefile, { id: id }));
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