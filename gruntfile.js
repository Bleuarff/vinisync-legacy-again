'use strict'

module.exports = function(grunt){
  // target = grunt.option('e') || 'dev'

  grunt.initConfig({

    concurrent: {
      options: { logConcurrentOutput: true },
      dev:
        {tasks: ['watch', 'nodemon']}
    },
    nodemon: {
      dev: {
        script: 'src/app.js',
        options: {
          watch: ['src/', 'config/', 'utils/', 'services/'],
          ext: 'js,yml',
          delay: 1000,
        }
      }
    },
    watch: {
    },
    exec: {
      debug: { cmd: 'node --inspect ./src/app.js' }
    },
    chequire: {
      all: ['src/**/*.js', 'utils/**/*.js']
    },
    browserify: {
      normalizer: {
        options: {
          browserifyOptions: {
            standalone: 'normalizer'
          },
        },
        files: {
          'assets/dist/normalizer.js': 'services/normalizer.js'
        }
      }
    },
  })

  grunt.loadNpmTasks('grunt-browserify')
  grunt.loadNpmTasks('grunt-concurrent')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-exec')
  grunt.loadNpmTasks('grunt-nodemon')

  grunt.registerTask('basis', ['browserify'])

  grunt.registerTask('default', ['basis', 'concurrent'])
  grunt.registerTask('debug', ['exec:debug'])

  // grunt.registerTask('build', ['basis', 'chequire', 'cachebuster', 'compress'])
  // grunt.registerTask('deploy', ['build', 'awsebtdeploy'])
}
