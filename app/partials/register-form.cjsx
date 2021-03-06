counterpart = require 'counterpart'
React = require 'react'
PromiseToSetState = require '../lib/promise-to-set-state'
auth = require '../api/auth'
Translate = require 'react-translate-component'
LoadingIndicator = require '../components/loading-indicator'
Tooltip = require '../components/tooltip'
debounce = require 'debounce'
apiClient = require '../api/client'

REMOTE_CHECK_DELAY = 1000
MIN_PASSWORD_LENGTH = 8

counterpart.registerTranslations 'en',
  registerForm:
    required: 'Required'
    looksGood: 'Looks good'
    userName: 'User name'
    badChars: 'Don’t use weird characters: %(chars)s'
    nameConflict: 'That username is taken'
    forgotPassword: 'Forget your password?'
    password: 'Password'
    passwordTooShort: 'Too short'
    confirmPassword: 'Confirm password'
    passwordsDontMatch: 'These don’t match'
    email: 'Email address'
    emailConflict: 'An account with this address already exists'
    realName: 'Real name'
    whyRealName: 'We’ll use this to give you credit in scientific papers, posters, etc'
    agreeToPrivacyPolicy: 'You agree to our %(link)s (required)'
    privacyPolicy: 'privacy policy'
    okayToEmail: 'It’s okay to send me email every once in a while.'
    register: 'Register'
    alreadySignedIn: 'Signed in as %(name)s'
    signOut: 'Sign out'

module.exports = React.createClass
  displayName: 'RegisterForm'

  mixins: [PromiseToSetState]

  getDefaultProps: ->
    project: {}

  getInitialState: ->
    user: null
    badNameChars: null
    nameConflict: null
    passwordTooShort: null
    passwordsDontMatch: null
    emailConflict: null
    agreedToPrivacyPolicy: null
    error: null

  componentDidMount: ->
    auth.listen @handleAuthChange
    @handleAuthChange()

  componentWillUnmount: ->
    auth.stopListening @handleAuthChange

  handleAuthChange: ->
    @promiseToSetState user: auth.checkCurrent()

  render: ->
    {badNameChars, nameConflict, passwordTooShort, passwordsDontMatch, emailConflict} = @state

    <form onSubmit={@handleSubmit}>
      <label>
        <span className="columns-container inline spread">
          <Translate content="registerForm.userName" />
          {if badNameChars?.length > 0
            chars = for char in badNameChars
              <kbd key={char}>{char}</kbd>
            <Translate className="form-help error" content="registerForm.badChars" chars={chars} />
          else if "nameConflict" of @state.pending
            <LoadingIndicator />
          else if nameConflict?
            if nameConflict
              <span className="form-help error">
                <Translate content="registerForm.nameConflict" />{' '}
                <a href="#/reset-password" onClick={@props.onSuccess}>
                  <Translate content="registerForm.forgotPassword" />
                </a>
              </span>
            else
              <span className="form-help success">
                <Translate content="registerForm.looksGood" />
              </span>}
        </span>
        <input type="text" ref="name" className="standard-input full" disabled={@state.user?} autoFocus onChange={@handleNameChange} />
      </label>

      <br />

      <label>
        <span className="columns-container inline spread">
          <Translate content="registerForm.password" />
          {if passwordTooShort
            <Translate className="form-help error" content="registerForm.passwordTooShort" />}
        </span>
        <input type="password" ref="password" className="standard-input full" disabled={@state.user?} onChange={@handlePasswordChange} />
      </label>

      <br />

      <label>
        <span className="columns-container inline spread">
          <Translate content="registerForm.confirmPassword" /><br />
          {if passwordsDontMatch?
            if passwordsDontMatch
              <Translate className="form-help error" content="registerForm.passwordsDontMatch" />
            else
              <Translate className="form-help success" content="registerForm.looksGood" />}
        </span>
        <input type="password" ref="confirmedPassword" className="standard-input full" disabled={@state.user?} onChange={@handlePasswordChange} />
      </label>

      <br />

      <label>
        <span className="columns-container inline spread">
          <Translate content="registerForm.email" />
          {if 'emailConflict' of @state.pending
            <LoadingIndicator />
          else if emailConflict?
            if emailConflict
              <span className="form-help error">
                <Translate content="registerForm.emailConflict" />{' '}
                <a href="#/reset-password" onClick={@props.onSuccess}>
                  <Translate content="registerForm.forgotPassword" />
                </a>
              </span>
            else
              <Translate className="form-help success" content="registerForm.looksGood" />
          else
            <Translate className="form-help info" content="registerForm.required" />}
        </span>
        <input type="text" ref="email" className="standard-input full" disabled={@state.user?} onChange={@handleEmailChange} />
      </label>

      <br />

      <label>
        <span className="columns-container inline spread">
          <Translate content="registerForm.realName" />
        </span>
        <input type="text" ref="realName" className="standard-input full" disabled={@state.user?} />
        <Translate component="span" className="form-help info" content="registerForm.whyRealName" />
      </label>

      <br />
      <br />

      <label>
        <input type="checkbox" ref="agreesToPrivacyPolicy" disabled={@state.user?} onChange={@handlePrivacyPolicyChange} />
        {privacyPolicyLink = <a href="#/todo/privacy"><Translate content="registerForm.privacyPolicy" /></a>; null}
        <Translate component="span" content="registerForm.agreeToPrivacyPolicy" link={privacyPolicyLink} />
      </label>

      <br />
      <br />

      <label>
        <input type="checkbox" ref="okayToEmail" disabled={@state.user?} onChange={@forceUpdate.bind this, null} />
        <Translate component="span" content="registerForm.okayToEmail" />
      </label><br />

      <p style={textAlign: 'center'}>
        {if 'user' of @state.pending
          <LoadingIndicator />
        else if @state.user?
          <span className="form-help warning">
            <Translate content="registerForm.alreadySignedIn" name={@state.user.display_name} />{' '}
            <button type="button" className="minor-button" onClick={@handleSignOut}><Translate content="registerForm.signOut" /></button>
          </span>
        else if @state.error?
          <span className="form-help error">{@state.error.toString()}</span>
        else
          <span>&nbsp;</span>}
      </p>

      <div>
        <button type="submit" className="standard-button full" disabled={not @isFormValid() or Object.keys(@state.pending).length isnt 0 or @state.user?}>
          <Translate content="registerForm.register" />
        </button>
      </div>
    </form>

  handleNameChange: ->
    name = @refs.name.getDOMNode().value

    exists = name.length isnt 0
    badChars = (char for char in name.split('') when char isnt encodeURIComponent char)

    @setState
      badNameChars: badChars
      nameConflict: null

    if exists and badChars.length is 0
      @debouncedCheckForNameConflict ?= debounce @checkForNameConflict, REMOTE_CHECK_DELAY
      @debouncedCheckForNameConflict name

  debouncedCheckForNameConflict: null
  checkForNameConflict: (username) ->
    @promiseToSetState nameConflict: auth.register(display_name: username).catch (error) ->
      error.message.match(/display_name(.+)taken/mi) ? false

  handlePasswordChange: ->
    password = @refs.password.getDOMNode().value
    confirmedPassword = @refs.confirmedPassword.getDOMNode().value

    exists = password.length isnt 0
    longEnough = password.length >= MIN_PASSWORD_LENGTH
    asLong = confirmedPassword.length >= password.length
    matches = password is confirmedPassword

    @setState
      passwordTooShort: if exists then not longEnough
      passwordsDontMatch: if exists and asLong then not matches

  handleEmailChange: ->
    @promiseToSetState emailConflict: Promise.resolve null # Cancel any existing request.

    email = @refs.email.getDOMNode().value
    if email.match /.+@.+\..+/
      @debouncedCheckForEmailConflict ?= debounce @checkForEmailConflict, REMOTE_CHECK_DELAY
      @debouncedCheckForEmailConflict email

  debouncedCheckForEmailConflict: null
  checkForEmailConflict: (email) ->
    @promiseToSetState emailConflict: auth.register({email}).catch (error) ->
      error.message.match(/email(.+)taken/mi) ? false

  handlePrivacyPolicyChange: ->
    @setState agreesToPrivacyPolicy: @refs.agreesToPrivacyPolicy.getDOMNode().checked

  isFormValid: ->
    {badNameChars, nameConflict, passwordsDontMatch, emailConflict, agreesToPrivacyPolicy} = @state
    badNameChars?.length is 0 and not nameConflict and not passwordsDontMatch and not emailConflict and agreesToPrivacyPolicy

  handleSubmit: (e) ->
    e.preventDefault()
    display_name = @refs.name.getDOMNode().value
    password = @refs.password.getDOMNode().value
    email = @refs.email.getDOMNode().value
    credited_name = @refs.realName.getDOMNode().value
    global_email_communication = @refs.okayToEmail.getDOMNode().checked
    project_id = @props.project?.id

    @setState error: null
    @props.onSubmit?()
    auth.register {display_name, password, email, credited_name, global_email_communication, project_id}
      .then =>
        @props.onSuccess? arguments...
      .catch (error) =>
        @setState {error}
        @props.onFailure? arguments...

  handleSignOut: ->
    auth.signOut()
