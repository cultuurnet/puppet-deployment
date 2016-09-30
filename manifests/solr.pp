class deployment::solr {

  solr::url: 'http://archive.apache.org/dist/lucene/solr/'
  solr::version: '4.9.0'
  solr::solr_downloads: '/var/tmp/solr_downloads'
  solr::java_home: '/usr/lib/jvm/java-8-oracle/jre'

  # TODO: new module ?
}
