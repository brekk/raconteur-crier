assert = require 'assert'
should = require 'should'
_ = require 'lodash'
Crier = require '../lib/crier'
dust = require 'dustjs-linkedin'
templateFixture = require './fixtures/crier.json'
rant = require 'rantjs'
chalk = require 'chalk'
path = require 'path'
rantify = (model)->
    _.each model, (value, key)->
        if _.isString value
            model[key] = rant value
        if _.isObject value
            child = rantify value
            model[key] = child
    return model

(($)->
    "use strict"
    try
        fixture = null
        findInTemplates = (name)->
            return _(fixture.templates).where {name: name}
                                       .last()
        reset = (done)->
            fixture = _.assign {}, templateFixture
            fixture.templates = _(fixture.templates).map((template)->
                unless template.name?
                    template.name = "test"
                unless template.template?
                    template.template = "<div></div>"
                unless template.model?
                    template.model = {}
                unless template.options?
                    template.options = {}
                return template
            ).value()
            $.sugarFileType = '.sugar'
            dust.cache = {}
            done()
        customAdd = (test, callback)->
            {name, template, model, options} = test
            args = [name, template]
            if options?.sugar? and options.sugar
                args.push true
            result = $.addAsPromise.apply($, args)
            result.then ()->
                callback test
        beforeEach reset
        afterEach reset
        describe 'Crier', ()->
            describe '.sugarFileType.get', ()->
                it 'should be .sugar by default', ()->
                    $.sugarFileType.should.equal '.sugar'
            describe '.sugarFileType.set', ()->
                it 'should allow for assignment of new sugarfile types', ()->
                    newType = '.pants'
                    $.sugarFileType = newType
                    $.sugarFileType.should.equal newType
            describe '.addAsPromise', ()->
                it "should add a new template to the dust.cache", (done)->
                    count = _.size fixture.templates
                    finish = _.after count, done
                    _.each fixture.templates, (test)->
                        {name, template, model, options} = test
                        args = [name, template]
                        if options?.sugar?
                            if options.sugar
                                finish()
                                return
                        $.addAsPromise.apply($, args).then ()->
                            {name, template, model, options} = test
                            dust.cache.should.have.property name
                            finish()
                        return
                it "should add a new template to the dust.cache and automatically convert from sugar", (done)->
                    count = _.size fixture.templates
                    finish = _.after count, done
                    _.each fixture.templates, (test)->
                        customAdd test, (out)->
                            {name, template, model, options} = out
                            dust.cache.should.have.property name
                            finish()
            describe '.removeAsPromise', ()->
                it 'should remove an existing template from the dust.cache', (done)->
                    count = _.size fixture.templates
                    finish = _.after (count*2), done
                    _.each fixture.templates, (test)->
                        customAdd test, (out)->
                            {name, template, model, options} = out
                            dust.cache.should.have.property name
                            finish()
                            $.removeAsPromise(test.name).then ()->
                                finish()
            describe '.has', ()->
                it "should prove that a template has been added to the dust.cache", ()->
                    _.each fixture.templates, (test)->
                        customAdd test, (out)->
                            {name, template, model, options} = out
                            dust.cache.should.have.property name
                            $.has(name).should.equal true
            describe '.create', ()->
                it 'should create a rendered template', (finish)->
                    count = _.size fixture.templates
                    done = _.after count, finish
                    _.each fixture.templates, (test, index)->
                        customAdd test, (out)->
                            {name, template, model, options} = out
                            $.create name, model, (err, templated)->
                                templated.should.be.ok
                                if templated?
                                    done()
                it 'should create a template rendering function given only one parameter', (finish)->
                    count = _.size fixture.templates
                    done = _.after count, finish
                    _.each fixture.templates, (test, index)->
                        customAdd test, (out)->
                            {name, template, model, options} = out
                            $.create name, model, (err, templated)->
                                templated.should.be.ok
                                if templated?
                                    done()

            describe '.createAsPromise', ()->
                it 'should return a function that returns a promise, given only one parameter', (finish)->
                    count = _.size fixture.templates
                    done = _.after count, finish
                    _.each fixture.templates, (test, index)->
                        customAdd test, (out)->
                            {name, template, model, options} = out
                            fx = $.createAsPromise name
                            fx.should.be.a.Function
                            promiseTest = fx(model)
                            promiseTest.then.should.be.ok
                            happy = (resolved)->
                                resolved.should.be.ok
                                done()
                            sad = (e)->
                                throw e
                            promiseTest.then happy, sad
                it 'should return a promise with a fulfilled template, given two parameters', (finish)->
                    count = _.size fixture.templates
                    done = _.after count, finish
                    _.each fixture.templates, (test, index)->
                        customAdd test, (out)->
                            {name, template, model, options} = out
                            promiseTest = $.createAsPromise name, model
                            promiseTest.then.should.be.ok
                            happy = (resolved)->
                                resolved.should.be.ok
                                done()
                            sad = (e)->
                                throw e
                            promiseTest.then happy, sad

            describe '.convertSugarToDust', ()->
                it 'should allow jade to be converted to dust', (finish)->
                    sugarPromise = $.convertSugarToDust '''
                    .test-class
                        strong|{model.fighter|s}
                    '''
                    sugarPromise.should.be.ok
                    sugarPromise.then.should.be.ok
                    resolve = (converted)->
                        converted.should.be.ok
                        converted.should.equal '<div class="test-class"><strong>{model.fighter|s}</strong></div>'
                        finish()

                    reject = (e)->
                        throw e
                    sugarPromise.then resolve, reject

            describe '.loadFileAsPromise', ()->
                it 'should fail when given only one parameter', (done)->
                    (
                        fileToLoad = path.normalize process.cwd() + '/' + fixture.files.parameters.one.path
                        loadFileOp = $.loadFileAsPromise fileToLoad
                        loadFileOp.should.be.ok
                        loadFileOp.then.should.be.ok
                        happy = (output)->
                            output.should.not.be.ok
                            output.should.not.be.a.String
                        sad = (e)->
                            e.should.be.ok
                            done()
                        loadFileOp.then happy, sad
                    ).should.throwError
                it 'should read a file via promise and add it to the dust.cache when given two parameters', (done)->
                    data = fixture.files.parameters.two
                    pathToFile = path.normalize process.cwd() + '/' + data.path
                    addFileOp = $.loadFileAsPromise pathToFile, data.name
                    addFileOp.should.be.ok
                    addFileOp.then.should.be.ok
                    happy = (output)->
                        output.should.be.ok
                        output.should.be.a.Function
                        done()
                    sad = (e)->
                        throw e
                    addFileOp.then happy, sad
                it 'should read a file, add it to the dust.cache, and vivify it when given vivify=true', (done)->
                    data = fixture.files.parameters.three.vivify
                    pathToFile = path.normalize process.cwd() + '/' + data.path
                    model = findInTemplates data.name
                    vivifyFileOp = $.loadFileAsPromise pathToFile, data.name, true
                    vivifyFileOp.should.be.ok
                    vivifyFileOp.then.should.be.ok
                    sad = (e)->
                        throw e
                    happy = (renderer)->
                        renderer.should.be.ok
                        renderer.should.be.a.Function
                        renderer(model).then (output)->
                            output.should.be.ok
                            done()
                    vivifyFileOp.then happy, sad

                it 'should read a file, add it to the dust.cache, and vivify it fully when given vivify={model}', (done)->
                    data = fixture.files.parameters.three['vivify-object']
                    pathToFile = path.normalize process.cwd() + '/' + data.path
                    model = findInTemplates data.vivify
                    vivifyFileOp = $.loadFileAsPromise pathToFile, data.name, model
                    vivifyFileOp.should.be.ok
                    vivifyFileOp.then.should.be.ok
                    happy = (output)->
                        output.should.be.ok
                        done()
                    sad = (e)->
                        throw e
                    vivifyFileOp.then happy, sad
    catch e
        console.log "Error during testing: ", e
        if e.stack?
            console.log e.stack
)(Crier)