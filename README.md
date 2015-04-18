# raconteur-crier

The crier is tied of the [raconteur][] module, which offers additional functionality (such as easy content management and a clean programmatic interface) but you can use this module independently as well.

## Installation

    npm install raconteur-crier --save

## Invocation

    var crier = require('raconteur-crier').crier;

### crier

The crier is a tool for converting markup (either straight HTML, [jade][], or jade-and-dust together, our preferred sugar syntax) into a template (a function which can be fed data and resolves itself into a view).

Here's an example file in the preferred sugar syntax:

**example-post.sugar** - an easy to learn, expressive combination of [dust][] and [jade][]:

    .post
        .meta
            header
                h1|{model.attributes.title}
                h2|By {model.attributes.author}
            span.timestamp|{model.attributes.date}
        ul.tags|{#model.attributes.tags}
            li.tag|{.}
            {/model.attributes.tags}
        p.content|{model.content|s}

Here's an example of using the crier module. In this example we're using mock content; we recommend using the crier with the [raconteur-scribe][] module, but the modules are designed to be modular enough to be used independently:

    var crier = require('raconteur-crier').crier;
    var fs = require('fs');
    # this example we'll do the reading ourselves, but there are other ways of adding content which we'll get to below.
    fs.readFile('./example-post.tpl', {encoding: 'utf8'}, function(e, content){
        if (!!e){
            console.log("Error during read:", e.toString());
            return
        }
        var useSugarSyntax = true;
        // this adds the template to the dust cache
        crier.add('namedTemplate', content, useSugarSyntax);
        mockContent = {
            model: {
                attributes: {
                    title: "Test",
                    author: "Brekk",
                    date: "3-30-15",
                    tags: [
                        "a",
                        "b",
                        "c"
                    ]
                },
                content: "<strong>hello</strong>"
            }
        }
        // this retrieves the named template from the dust cache, and populates it with content
        crier.create('namedTemplate', mockContent, function(e, content){
            if (!!e){
                console.log(e);
                return
            }
            console.log(content);
            // prints converted HTML
        });
    });

In addition to reading files from a source, you can also point the crier at files during runtime:

    var onLoaded = function(data){
        console.log("Things loaded.", data.attributes, data.content);
    };
    var onError = function(e){
        console.log("Error during loadFile", e.toString());
    };
    crier.loadFileAsPromise('./example-post.sugar', 'namedTemplate').then(onLoaded, onError);

Please read the tests for a better understanding of all the possible options for the crier.

### Herald

The Herald is essentially a re-wrapper for the crier. It allows you to create a custom instance of the crier with templates pre-loaded (they can either be loaded at runtime or pre-added to the output file), so the generated file already has access to the templates you want to use.

It's pretty straightforward to use, but the main configurable options are in the `herald.export` method.

**retemplater.js**

    var fs = require('fs');
    var herald = require('raconteur-crier').herald;
    herald.add('./post.sugar');
    herald.add('./page.sugar');
    var success = function(content){
        fs.writeFile('./herald-custom.js', content, {encoding: 'utf8'}, function(){
            console.log("success");
        });
    };
    var failure = function(e){
        console.log("Error creating custom crier.", e.toString());
    };
    var settings = {
        sugar: true,
        mode: 'inline-convert',
        inflate: false
    };
    herald.export(settings).then(success, failure);

Once that retemplater file has been run, you should have a custom version of the crier which you can use instead of it:

    var crier = require('./herald-custom');
    crier.has('post.sugar'); // prints true
    crier.has('page.sugar'); // prints true
    crier.has('summary.sugar'); // prints false

[raconteur]: https://www.npmjs.com/package/raconteur "The raconteur module"
[raconteur-scribe]: https://www.npmjs.com/package/raconteur-scribe "The raconteur-scribe module"
[jade]: https://www.npmjs.com/package/jade "The jade module"
[dust]: https://www.npmjs.com/package/dustjs-linkedin "The dustjs-linkedin module"