<template>
    <div class="column  justify-center items-center q-pa-lg">
      <q-card v-if="formState === 'signUp'" square class="shadow-24">
        <q-card-section class="ubc-color">
          <div class="text-h6">New User</div>
        </q-card-section>
        <q-card-section>
          <q-form>
            <q-input 
              square clearable 
              v-model="form.username" 
              clear-icon="close"
              type="email" 
              label="Email">
              <template v-slot:prepend>
                <q-icon name="email" />
              </template>
            </q-input>
            <q-input 
              square clearable 
              v-model="form.password" 
              clear-icon="close"
              @focus="hasLoginError=false"
              type="password" 
              label="Password">
              <template v-slot:prepend>
                <q-icon name="lock" />
              </template>
            </q-input>
          </q-form>
        </q-card-section>
        <q-card-section style="max-width: 300px;" class="text-center q-pa-sm" v-if="hasLoginError" >
          <span class="error text-subtitle2 ">{{ loginError}} </span>
        </q-card-section>
        <q-card-actions class="q-px-lg">
          <q-btn unelevated size="lg" @click="signUp" class="ubc-color full-width" label="CREATE" />
        </q-card-actions>
        <q-card-section class="text-center q-pa-sm">
          <q-btn flat size="sm" @click="toggleLogin" color="black" label="Already have an account? Sign in" />
        </q-card-section>
      </q-card>

    <q-card v-if="formState === 'confirmSignUp'" square class="shadow-24">
       <q-card-section class="ubc-color">
        <div class="text-h6">Confirmation</div>
        <div class="text-subtitle2">A confirmation code was sent to {{ form.email }}. Please, check your email.</div>
       </q-card-section>
        <q-card-section>
          <q-form>
            <q-input 
              square clearable 
              v-model="form.authCode" 
              clear-icon="close"
              label="Authentication Code">
              <template v-slot:prepend>
                <q-icon name="input" />
              </template>
            </q-input>
          </q-form>
        </q-card-section>
        <q-card-section class="q-pa-sm" v-if="hasLoginError">
          <span class="bg-negative text-caption">{{ loginError}} </span>
        </q-card-section>
        <q-card-actions class="q-px-lg">
          <q-btn unelevated size="lg" @click="confirmSignUp" class="ubc-color full-width" label="SUBMIT" />
        </q-card-actions>     
        <q-card-section class="text-center q-pa-sm">
          <q-btn flat size="sm" @click="resendSignUp" color="black" label="Send another code" />
        </q-card-section>   
      </q-card>
    </div>
</template>

<style scoped>
.ubc-color {
  background-color: rgb(1, 33, 68);
  color: #fff
}
.error {
  background-color: red;
  color: #fff;
  word-wrap: break-word;
}
</style>

<script>
import { Auth } from 'aws-amplify'

export default {
  name: 'SignUp',
  data() {
    return {
      formState: 'signUp',
      hasLoginError: false,
      loginError: '',
      form: {
        password: '',
        username: '',
        email: '',
        authCode: ''
      }
    }
  },
  methods: {
    async signUp() {
      try {
        this.loginError = '';
        this.hasLoginError = false;
        this.form.email = this.form.username;
        const { username, password, email } = this.form
        await Auth.signUp({
          username, password, attributes: { email }
        })
        this.formState = 'confirmSignUp'
      } catch (error) {
        this.loginError = error.message;
        this.hasLoginError = true;
      }       
    },
    async confirmSignUp() {
      try {
        this.loginError = '';
        this.hasLoginError = false;
        const { username, authCode } = this.form
        await Auth.confirmSignUp(username, authCode)
        this.$q.notify({
            color: "teal",
            icon: "thumb_up",
            message: "User created!! ",
            position: "right"
        });
        this.$router.push("/auth");
      } catch (error) {
        this.loginError = error.message;
        this.hasLoginError = true;
      }        
    },
    toggleLogin() {
        this.$router.push("/auth");
    },
    async resendSignUp() {
      const { username, authCode } = this.form
      await Auth.resendSignUp(username, authCode);
      this.$q.notify({
          color: "teal",
          icon: "thumb_up",
          message: "Auth code re-sent",
          position: "right"
      });
    }
  }
}
</script>