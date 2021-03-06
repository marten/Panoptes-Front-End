React = require 'react'
BoundResourceMixin = require '../lib/bound-resource-mixin'
AutoSave = require '../components/auto-save'
handleInputChange = require '../lib/handle-input-change'
ChangeListener = require '../components/change-listener'
auth = require '../api/auth'
PromiseRenderer = require '../components/promise-renderer'
ImageSelector = require '../components/image-selector'
apiClient = require '../api/client'
putFile = require '../lib/put-file'

MAX_AVATAR_SIZE = 65536
MIN_PASSWORD_LENGTH = 8

ChangePasswordForm = React.createClass
  displayName: 'ChangePasswordForm'

  getDefaultProps: ->
    user: {}

  getInitialState: ->
    old: ''
    new: ''
    confirmation: ''
    inProgress: false
    success: false
    error: null

  render: ->
    <form ref="form" onSubmit={@handleSubmit}>
      <p>
        <strong>Change your password</strong>
      </p>

      <table className="standard-table">
        <tbody>
          <tr>
            <td>Current password</td>
            <td><input type="password" className="standard-input" size="20" onChange={(e) => @setState old: e.target.value} /></td>
          </tr>
          <tr>
            <td>New password</td>
            <td>
              <input type="password" className="standard-input" size="20" onChange={(e) => @setState new: e.target.value} />
              {if @state.new.length isnt 0 and @tooShort()
                <small className="form-help error">That’s too short</small>}
            </td>
          </tr>
          <tr>
            <td>Confirm new password</td>
            <td>
              <input type="password" className="standard-input" size="20" onChange={(e) => @setState confirmation: e.target.value} />
              {if @state.confirmation.length >= @state.new.length - 1 and @doesntMatch()
                <small className="form-help error">These don’t match</small>}
            </td>
          </tr>
        </tbody>
      </table>

      <p>
        <button type="submit" className="standard-button" disabled={not @state.old or not @state.new or @tooShort() or @doesntMatch() or @state.inProgress}>Change</button>{' '}

        {if @state.inProgress
          <i className="fa fa-spinner fa-spin form-help"></i>
        else if @state.success
          <i className="fa fa-check-circle form-help success"></i>
        else if @state.error
          <small className="form-help error">{@state.error.toString()}</small>}
      </p>
    </form>

  tooShort: ->
    @state.new.length < MIN_PASSWORD_LENGTH

  doesntMatch: ->
    @state.new isnt @state.confirmation

  handleSubmit: (e) ->
    e.preventDefault()

    current = @state.old
    replacement = @state.new

    @setState
      inProgress: true
      success: false
      error: null

    auth.changePassword {current, replacement}
      .then =>
        @setState success: true
        @refs.form.getDOMNode().reset()
      .catch (error) =>
        @setState {error}
      .then =>
        @setState inProgress: false

UserSettingsPage = React.createClass
  displayName: 'UserSettingsPage'

  getDefaultProps: ->
    user: {}

  getInitialState: ->
    avatarError: null

  render: ->
    @getAvatarSrc ?= @props.user.get 'avatar'
      .then ([avatar]) ->
        avatar.src
      .catch ->
        ''

    <div>
      <div className="columns-container">
        <div className="content-container">
          Avatar<br />
          <PromiseRenderer promise={@getAvatarSrc} then={(avatarSrc) =>
            placeholder = <div className="form-help content-container">Drop an image here</div>
            <ImageSelector maxSize={MAX_AVATAR_SIZE} ratio={1} defaultValue={avatarSrc} placeholder={placeholder} onChange={@handleAvatarChange} />
          } />
          {if @state.avatarError
            <div className="form-help error">{@state.avatarError.toString()}</div>}
        </div>

        <hr />

        <div className="content-container column">
          <p>
            <AutoSave resource={@props.user}>
              <span className="form-label">Credited name</span>
              <br />
              <input type="text" className="standard-input full" name="credited_name" value={@props.user.credited_name} onChange={handleInputChange.bind @props.user} />
            </AutoSave>
            <span className="form-help">Public; we’ll use this to give acknowledgement in papers, on posters, etc.</span>
          </p>

          <p>
            <AutoSave resource={@props.user}>
              <label>
                <input type="checkbox" name="global_email_communication" checked={@props.user.global_email_communication} onChange={handleInputChange.bind @props.user} />{' '}
                Get general Zooniverse email updates
              </label>
            </AutoSave>
          </p>
        </div>
      </div>

      <hr />

      <div className="content-container">
        <p><strong>Project email preferences</strong></p>
        <table>
          <thead>
            <tr>
              <th><i className="fa fa-envelope-o fa-fw"></i></th>
              <th>Project</th>
            </tr>
          </thead>
          <PromiseRenderer promise={@props.user.get 'project_preferences'} pending={=> <tbody></tbody>} then={(projectPreferences) =>
            <tbody>
              {for projectPreference in projectPreferences then do (projectPreference) =>
                <PromiseRenderer key={projectPreference.id} promise={projectPreference.get 'project'} then={(project) =>
                  <ChangeListener target={projectPreference} handler={=>
                    <tr>
                      <td><input type="checkbox" name="email_communication" checked={projectPreference.email_communication} onChange={@handleProjectEmailChange.bind this, projectPreference} /></td>
                      <td>{project.display_name}</td>
                    </tr>
                  } />
                } />}
            </tbody>
          } />
        </table>
      </div>

      <hr />

      <div className="content-container">
        <ChangePasswordForm {...@props} />
      </div>
    </div>

  handleAvatarChange: (file) ->
    @setState avatarError: null
    apiClient.post @props.user._getURL('avatar'), media: content_type: file.type
      .then ([avatar]) =>
        console.log 'Will put file to', avatar.src
        putFile avatar.src, file
      .then =>
        @props.user.uncacheLink 'avatar'
        @getAvatarSrc = null
        @props.user.emit 'change'
      .catch (error) =>
        @setState avatarError: error

  handleProjectEmailChange: (projectPreference, args...) ->
    handleInputChange.apply projectPreference, args
    projectPreference.save()

module.exports = React.createClass
  displayName: 'UserSettingsPageWrapper'

  render: ->
    <ChangeListener target={auth} handler={=>
      <PromiseRenderer promise={auth.checkCurrent()} then={(user) =>
        if user?
          <ChangeListener target={user} handler={=>
            <UserSettingsPage user={user} />
          } />
        else
          <div className="content-container">
            <p>You’re not signed in.</p>
          </div>
      } />
    } />
