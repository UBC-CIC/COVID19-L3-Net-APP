<template>
  <q-td>
    <q-btn
      flat
      :color="
        row.code == '2'
          ? 'black'
          : row.code == '3'
          ? 'red'
          : row.code == '99'
          ? 'gray'
          : 'orange'
      "
      size="lg"
      :icon="
        row.code == '2'
          ? 'analytics'
          : row.code == '3'
          ? 'error'
          : row.code == '99'
          ? 'hide_source'
          : 'query_builder'
      "
      @click="showModel(row.url)"
    >
      <q-tooltip
        content-class="bg-black"
        content-style="font-size: 16px"
        :offset="[10, 10]"
        >{{ row.msg }}</q-tooltip
      >
    </q-btn>
  </q-td>
</template>

<script type="text/javascript">

export default {
  name: "ModelStatus",
  props: ['row'],
  data() {
      return {
          urs: ''
      }      
  },
  methods: {
    showModel(url) {
        console.log(url);
        window.open(url,'_blank');
    }
  }
};

</script>