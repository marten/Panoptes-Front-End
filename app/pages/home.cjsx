counterpart = require 'counterpart'
React = require 'react'
Translate = require 'react-translate-component'
{Link} = require 'react-router'
apiClient = require '../api/client'
PromiseRenderer = require '../components/promise-renderer'
ZooniverseLogoType = require '../partials/zooniverse-logotype'
OwnedCard = require '../partials/owned-card'
alert = require '../lib/alert'
LoginDialog = require '../partials/login-dialog'

FEATURED_PRODUCT_IDS = if process.env.NODE_ENV is 'production'
  ['11', '6', '3']
else
  ['231', '405', '272', '76']

counterpart.registerTranslations 'en',
  home:
    hero:
      title: 'People-Powered Research'
      tagline: '''The Zooniverse is the largest online platform for collaborative volunteer research,
      and an opportunity for people around the world to contribute to real discoveries in fields from
      astronomy to zoology, and everything in between.'''
      button: 'Get involved now!'
    about:
      contribute:
        title: 'Contribute to new research'
        content: '''The Zooniverse lets everyone take part in real, cutting-edge research online in many
        fields across the sciences, humanities, and more. There's no previous experience required;
        just pick a project and get started right away.'''
      explore:
        title: 'Explore incredible worlds'
        content: '''Astronomical marvels, exotic wildlife in their natural habitats, original historical
        documents—these are just a few of the fascinating things you’ll get to experience.
        In many cases, you'll be seeing things no one has seen before.'''
      collaborate:
        title: 'Collaborate with researchers'
        content:'''Professional researchers and volunteers work together on our discussion boards
        to explore and analyse project data. Much of the most exciting research produced by
        the Zooniverse originates from these partnerships.'''
      discover:
        title: 'Discover, teach, and learn'
        content: '''Our platform offers many opportunities for education, from using projects
        in classrooms to sharing information between volunteers. You can even use the Project
        Builder to create your very own Zooniverse project!'''
    featuredProjects:
      title: 'Get started on a project right now!'
      tagline: 'These are just a few of our projects.'
      button: 'See all projects'

module.exports = React.createClass
  displayName: 'HomePage'

  componentDidMount: ->
    document.documentElement.classList.add 'on-home-page'

  componentWillUnmount: ->
    document.documentElement.classList.remove 'on-home-page'

  render: ->
    aboutItems = ['contribute', 'explore', 'collaborate', 'discover']

    <div className="home-page">
      <section className="hero on-dark">
        <ZooniverseLogoType />
        <h3 className="hero-title"><Translate content="home.hero.title" /></h3>
        <p className="hero-tagline"><Translate content="home.hero.tagline" /></p>
        <Link to="projects" className="call-to-action standard-button hero-button x-large"><Translate content="home.hero.button" /></Link>
      </section>
      <section className="about-zooniverse">
        <div className="about-items-list">
          {for item in aboutItems
            <div key={item} className="about-item">
              <div className="about-item-wrapper">
                <img className="about-image" src="./assets/home-#{item}.gif" alt="" />
                <div className="about-item-content">
                  <Translate component="h5" content="home.about.#{item}.title" />
                  <Translate component="p" content="home.about.#{item}.content" />
                </div>
              </div>
            </div>
          }
        </div>
      </section>
      <section className="featured-projects content-container">
        <Translate component="h5" content="home.featuredProjects.title" />
        <Translate component="p" content="home.featuredProjects.tagline" />
        <PromiseRenderer promise={apiClient.type('projects').get(FEATURED_PRODUCT_IDS)}>{(projects) =>
          if projects?
            <div className="featured-projects-list">
            {for project in projects
              <OwnedCard key={project.id} resource={project} linkTo="project-home" translationObjectName="projectsPage" imagePromise={project.get 'avatar'}/>
            }
            </div>
        }</PromiseRenderer>
        <Link to="projects" className="call-to-action standard-button x-large"><Translate content="home.featuredProjects.button" /></Link>
      </section>

    </div>

  showLoginDialog: (which) ->
    alert (resolve) ->
      <LoginDialog which={which} onSuccess={resolve} />
