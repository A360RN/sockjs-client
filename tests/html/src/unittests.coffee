module('Utils')

u = SockJS.getUtils()

test 'random_string', ->
    notEqual(u.random_string(8), u.random_string(8))
    for i in [1,2,3,128]
        equal(u.random_string(i).length, i)
    equal(u.random_string(4, 1), 'aaaa')

test 'random_number_string', ->
    for i in [0..10]
        equal(u.random_number_string(10).length, 1)
        equal(u.random_number_string(100).length, 2)
        equal(u.random_number_string(1000).length, 3)
        equal(u.random_number_string(10000).length, 4)
        equal(u.random_number_string(100000).length, 5)

test 'getOrigin', ->
    equal(u.getOrigin('http://a.b/'), 'http://a.b')
    equal(u.getOrigin('http://a.b/c'), 'http://a.b')
    equal(u.getOrigin('http://a.b:123/c'), 'http://a.b:123')

test 'objectExtend', ->
    deepEqual(u.objectExtend({}, {}), {})
    a = {a:1};
    equal(u.objectExtend(a, {}), a)
    equal(u.objectExtend(a, {b:1}), a)
    a = {a:1}; b = {b:2}
    deepEqual(u.objectExtend(a, b), {a:1, b:2})
    deepEqual(a, {a:1, b:2})
    deepEqual(b, {b:2})

test 'bind', ->
    o = {}
    fun = ->
        return this
    deepEqual(fun(), window)
    bound_fun = u.bind(fun, o)
    deepEqual(bound_fun(), o)

test 'amendUrl', ->
    dl = document.location

    equal(u.amendUrl('//blah:1/abc'), dl.protocol + '//blah:1/abc')
    equal(u.amendUrl('/abc'), dl.protocol + '//' + dl.host + '/abc')
    equal(u.amendUrl('/'), dl.protocol + '//' + dl.host)
    equal(u.amendUrl('http://a:1/abc'), 'http://a:1/abc')
    equal(u.amendUrl('http://a:1/abc/'), 'http://a:1/abc')
    equal(u.amendUrl('http://a:1/abc//'), 'http://a:1/abc')
    t = -> u.amendUrl('')
    raises(t, 'Wrong url')
    t = -> u.amendUrl(false)
    raises(t, 'Wrong url')

test 'arrIndexOf', ->
    a = [1,2,3,4,5]
    equal(u.arrIndexOf(a, 1), 0)
    equal(u.arrIndexOf(a, 5), 4)
    equal(u.arrIndexOf(a, null), -1)
    equal(u.arrIndexOf(a, 6), -1)

test 'arrSkip', ->
    a = [1,2,3,4,5]
    deepEqual(u.arrSkip(a, 1), [2,3,4,5])
    deepEqual(u.arrSkip(a, 2), [1,3,4,5])
    deepEqual(u.arrSkip(a, 11), [1,2,3,4,5])
    deepEqual(u.arrSkip(a, 'a'), [1,2,3,4,5])
    deepEqual(u.arrSkip(a, '1'), [1,2,3,4,5])

test 'quote', ->
    equal(u.quote(''), '""')
    equal(u.quote('a'), '"a"')
    ok(u.arrIndexOf(['"\\t"', '"\\u0009"'], u.quote('\t')) isnt -1)
    ok(u.arrIndexOf(['"\\n"', '"\\u000a"'], u.quote('\n')) isnt -1)
    equal(u.quote('\x00\udfff\ufffe\uffff'), '"\\u0000\\udfff\\ufffe\\uffff"')
    # Unicode surrogates, formally incorrect unicode datapoints:
    equal(u.quote('\ud85c\udff7\ud800\ud8ff'), '"\\ud85c\\udff7\\ud800\\ud8ff"')
    equal(u.quote('\u2000\u2001\u0300\u0301'), '"\\u2000\\u2001\\u0300\\u0301"')

    # And a sanity check.
    c = for i in [0..65535]
            String.fromCharCode(i)
    all_chars = c.join('')
    ok(JSON.parse(u.quote(all_chars)) is all_chars, "Quote/unquote all 64K chars.")

test 'detectProtocols', ->
    chrome_probed = {
        'websocket': true
        'xdr-streaming': false
        'xhr-streaming': true
        'iframe-eventsource': true
        'iframe-htmlfile': true
        'xdr-polling': false
        'xhr-polling': true
        'iframe-xhr-polling': true
        'jsonp-polling': true
    }
    # Chrome
    deepEqual(u.detectProtocols(chrome_probed, null, {}),
            ['websocket', 'xhr-streaming', 'xhr-polling'])
    deepEqual(u.detectProtocols(chrome_probed, null, {websocket:false}),
            ['xhr-streaming', 'xhr-polling'])
    # Opera
    opera_probed = {
        'websocket': false
        'xdr-streaming': false
        'xhr-streaming': false
        'iframe-eventsource': true
        'iframe-htmlfile': true
        'xdr-polling': false
        'xhr-polling': false
        'iframe-xhr-polling': true
        'jsonp-polling': true
    }
    deepEqual(u.detectProtocols(opera_probed, null, {}),
            ['iframe-eventsource', 'iframe-xhr-polling'])
    # IE 6, IE 7
    ie6_probed = {
        'websocket': false
        'xdr-streaming': false
        'xhr-streaming': false
        'iframe-eventsource': false
        'iframe-htmlfile': false
        'xdr-polling': false
        'xhr-polling': false
        'iframe-xhr-polling': false
        'jsonp-polling': true
    }
    deepEqual(u.detectProtocols(ie6_probed, null, {}),
            ['jsonp-polling'])
    # IE 8, IE 9
    ie8_probed = {
        'websocket': false
        'xdr-streaming': true
        'xhr-streaming': false
        'iframe-eventsource': false
        'iframe-htmlfile': true
        'xdr-polling': true
        'xhr-polling': false
        'iframe-xhr-polling': true
        'jsonp-polling': true
    }
    deepEqual(u.detectProtocols(ie8_probed, null, {}),
            ['xdr-streaming', 'xdr-polling'])
    deepEqual(u.detectProtocols(ie8_probed, null, {cookie_needed:true}),
            ['iframe-htmlfile', 'iframe-xhr-polling'])

test "EventEmitter", ->
    expect(4)
    r = new SockJS('//wrongdomainthatdoesntresolveatall/abc', [])
    r.addEventListener 'message', -> ok(true)
    r.onmessage = -> fail(true)
    bluff = -> fail(true)
    r.addEventListener 'message', bluff
    r.removeEventListener 'message', bluff
    r.addEventListener 'message', bluff
    r.addEventListener 'message', -> ok(true)
    r.onmessage = -> ok(true)
    r.removeEventListener 'message', bluff
    r.dispatchEvent({type:'message'})

    # Adding the same eventlistener should be indempotent (sockjs-client #4).
    single = -> ok(true)
    r.addEventListener 'close', single
    r.addEventListener 'close', single
    r.dispatchEvent({type:'close'}) # 1 callback run
    r.removeEventListener 'close', single
    r.dispatchEvent({type:'close'}) # 0 runs
