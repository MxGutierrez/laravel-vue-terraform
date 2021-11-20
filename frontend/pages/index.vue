<template>
  <Tutorial :message="message" />
</template>

<script>
import { Context } from '@nuxt/types';

export default {
  // async mounted() {
  //   try{
  //     const { data } = await this.$axios.get('/test');
  //     this.message = data;
  //   } catch (ex) {
  //     console.log(ex);
  //   }
  // },
  // data: () => ({
  //   message: ''
  // })
  async asyncData({ $axios }) {
    try {
      const { data } = await $axios.get('/test');
      return {
        message: data
      }
    } catch (ex) {
      console.log('ERROR', ex);
      return {
        message: ex.response.data.message
      }
    }
  }
}
</script>
