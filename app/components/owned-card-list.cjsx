counterpart = require 'counterpart'
React = require 'react'
TitleMixin = require '../lib/title-mixin'
Translate = require 'react-translate-component'
apiClient = require '../api/client'
PromiseRenderer = require '../components/promise-renderer'
OwnedCard = require '../partials/owned-card'
{Link} = require 'react-router'

module.exports = React.createClass
  displayName: 'OwnedCardList'

  propTypes:
    imagePromise: React.PropTypes.func.isRequired
    listPromise: React.PropTypes.object.isRequired
    cardLink: React.PropTypes.string.isRequired
    translationObjectName: React.PropTypes.string.isRequired
    ownerName: React.PropTypes.string
    heroClass: React.PropTypes.string
    heroNav: React.PropTypes.node

  componentDidMount: ->
    document.documentElement.classList.add 'on-secondary-page'

  componentWillUnmount: ->
    document.documentElement.classList.remove 'on-secondary-page'

  userForTitle: ->
    if @props.ownerName
      "#{@props.ownerName}'s"
    else
      'All'

  render: ->
    <div className="secondary-page all-resources-page">
      <section className={"hero #{@props.heroClass}"}>
        <div className="hero-container">
          <Translate component="h1" user={@userForTitle()} content={"#{@props.translationObjectName}.title"} />
          {if @props.heroNav?
            @props.heroNav}
        </div>
      </section>
      <section className="resources-container">
        <PromiseRenderer promise={@props.listPromise}>{(ownedResources) =>
          if ownedResources?.length > 0
            <div>
              <div className="resource-results-counter">
                <Translate count={ownedResources.length} content="#{@props.translationObjectName}.countMessage" component="p" />
              </div>
              <div className="card-list">
                {for resource in ownedResources
                   <OwnedCard
                     key={resource.id}
                     resource={resource}
                     imagePromise={@props.imagePromise(resource)}
                     linkTo={@props.cardLink}
                     translationObjectName={@props.translationObjectName}/>}
              </div>
              <nav>
                {if meta = ownedResources[0].getMeta()
                  <nav className="pagination">
                    {for page in [1..meta.page_count]
                      <Link to={@props.linkTo} query={{page}} key={page} className="pill-button">{page}</Link>}
                  </nav>}
              </nav>
            </div>
          else if ownedResources?.length is 0
            <Translate content="#{@props.translationObjectName}.notFoundMessage" component="div" />
          else
            <Translate content="#{@props.translationObjectName}.loadMessage" component="div" />
        }</PromiseRenderer>
      </section>
    </div>
