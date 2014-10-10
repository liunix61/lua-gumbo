local gumbo = require "gumbo"
local assert, rep, pcall = assert, string.rep, pcall
local _ENV = nil

local input = [[
<div id="main" class="foo bar baz etc">
    <h1 id="heading">Title <!--comment --></h1>
</div>
]]

local document = assert(gumbo.parse(input))
local html = assert(document.documentElement)
local head = assert(document.head)
local body = assert(document.body)
local main = assert(document:getElementById("main"))
local heading = assert(document:getElementById("heading"))
local text = assert(heading.childNodes[1])
local comment = assert(heading.childNodes[2])

assert(document:getElementsByTagName("head")[1] == head)
assert(document:getElementsByTagName("body")[1] == body)
assert(document:getElementsByTagName("div")[1] == main)
assert(document:getElementsByTagName("*").length == 5)
assert(document:getElementsByTagName("").length == 0)
assert(body:getElementsByTagName("h1")[1] == heading)
assert(body:getElementsByTagName("*").length == 2)
local tendivs = assert(gumbo.parse(rep("<div>", 10)))
assert(tendivs:getElementsByTagName("div").length == 10)

assert(document.nodeName == "#document")
assert(#document.childNodes == 1)
assert(#document.children == 1)
assert(document.children[1] == html)
assert(document.childNodes[1] == html)
assert(document.firstChild == body.parentNode)
assert(document.lastChild == body.parentNode)
assert(document.contentType == "text/html")
assert(document.characterSet == "UTF-8")
assert(document.URL == "about:blank")
assert(document.documentURI == document.URL)
assert(document.compatMode == "BackCompat")
assert(document.ownerDocument == nil)
assert(document.nodeValue == nil)
document.nodeName = "this-is-readonly"
assert(document.nodeName == "#document")

assert(document:createElement("p").localName == "p")
assert(pcall(document.createElement, document, "Inv@lidName") == false)
assert(document:createTextNode("xyz..").data == "xyz..")
assert(document:createComment(" etc ").data == " etc ")
assert(document:createComment("comment "):isEqualNode(comment) == true)
assert(document:createComment("........"):isEqualNode(comment) == false)
assert(document:createTextNode("Title "):isEqualNode(text) == true)
assert(document:createTextNode("......"):isEqualNode(text) == false)

local newelem = assert(document:createElement("div"))
assert(newelem.localName == "div")
assert(newelem.namespaceURI == "http://www.w3.org/1999/xhtml")
assert(newelem.attributes.length == 0)
newelem:setAttribute("test", "...")
assert(newelem.attributes.length == 1)
newelem:setAttribute("test", "---")
assert(newelem.attributes.length == 1)
newelem:setAttribute("xyz", "+++")
assert(newelem.attributes.length == 2)
assert(newelem:getAttribute("test") == "---")
assert(newelem:getAttribute("xyz") == "+++")
assert(newelem:getAttribute("xyz") == newelem.attributes[2].value)

assert(text.parentElement == heading)
assert(comment.parentElement == heading)
assert(body.parentElement == html)
assert(document.parentElement == nil)
assert(html.parentElement == nil)

assert(html.childElementCount == 2)
assert(body.childElementCount == 1)
assert(main.childElementCount == 1)
assert(heading.childElementCount == 0)

-- TODO: Test these 2 getters on Elements with many childNodes
assert(html.firstElementChild == head)
assert(html.lastElementChild == body)
assert(body.firstElementChild == main)
assert(body.lastElementChild == main)

assert(html.localName == "html")
assert(html.nodeType == document.ELEMENT_NODE)
assert(html.parentNode == document)
assert(html.ownerDocument == document)
assert(html.nodeValue == nil)
assert(html.innerHTML == "<head></head><body>"..input.."</body>")
assert(html.outerHTML == "<html><head></head><body>"..input.."</body></html>")

assert(document:contains(html) == true)
assert(document:contains(comment) == true)
assert(html:contains(html) == true)
assert(html:contains(head) == true)
assert(html:contains(body) == true)
assert(html:contains(main) == true)
assert(html:contains(heading) == true)
assert(html:contains(text) == true)
assert(text:contains(text) == true)
assert(comment:contains(comment) == true)
assert(text:contains(heading) == false)
assert(comment:contains(main) == false)
assert(html:contains(document) == false)
assert(html:contains(nil) == false)
assert(heading:contains(main) == false)
assert(body:contains(html) == false)
assert(head:contains(body) == false)

assert(head.childNodes.length == 0)
assert(head.ownerDocument == document)
assert(head.innerHTML == "")
assert(head.outerHTML == "<head></head>")

assert(body == html.childNodes[2])
assert(body.nodeName == "BODY")
assert(body.nodeType == document.ELEMENT_NODE)
assert(body.localName == "body")
assert(body.parentNode.localName == "html")
assert(body.ownerDocument == document)
assert(body.innerHTML == input)
assert(body.outerHTML == "<body>" .. input .. "</body>")

assert(main == body[1])
assert(main:getElementsByTagName("div").length == 0)
assert(main.nodeName == "DIV")
assert(main.nodeName == main.tagName)
assert(main:hasAttribute("class") == true)
assert(main:getAttribute("class") == "foo bar baz etc")
assert(main.id == "main")
assert(main.id == main.attributes.id.value)
assert(main.className == "foo bar baz etc")
assert(main.className == main.attributes.class.value)
assert(main.classList[1] == "foo")
assert(main.classList[2] == "bar")
assert(main.classList[3] == "baz")
assert(main.classList[4] == "etc")
assert(main.classList.length == 4)
assert(main:hasChildNodes() == true)

local mainclone = assert(main:cloneNode())
assert(mainclone.nodeName == "DIV")
assert(mainclone:getAttribute("class") == "foo bar baz etc")
assert(mainclone.attributes.id.value == "main")
assert(mainclone.attributes[1].value == "main")
assert(main.classList.length == 4)
assert(mainclone:hasChildNodes() == false)
-- TODO: assert(mainclone:isEqualNode(main) == true)
-- TODO: assert(mainclone:isEqualNode(body) == false)

assert(text.nodeName == "#text")
assert(text.nodeType == document.TEXT_NODE)
assert(text.data == "Title ")
assert(text.nodeValue == text.data)
assert(text.length == #text.data)
assert(text.parentNode == heading)
assert(text.ownerDocument == document)

local textclone = assert(text:cloneNode())
assert(textclone.data == text.data)
assert(textclone.nodeName == "#text")
assert(textclone.parentNode == nil)
assert(textclone:isEqualNode(text) == true)
assert(textclone:isEqualNode(comment) == false)
assert(textclone:isEqualNode(heading) == false)

assert(comment.nodeName == "#comment")
assert(comment.nodeType == document.COMMENT_NODE)
assert(comment.data == "comment ")
assert(comment.nodeValue == comment.data)
assert(comment.length == #comment.data)
assert(comment.parentNode == heading)
assert(comment.ownerDocument == document)

local commentclone = assert(comment:cloneNode())
assert(commentclone.data == comment.data)
assert(commentclone.nodeName == "#comment")
assert(commentclone.parentNode == nil)
assert(commentclone:isEqualNode(comment) == true)
assert(commentclone:isEqualNode(text) == false)
assert(commentclone:isEqualNode(document) == false)

assert(heading.parentNode == main)
assert(heading.ownerDocument == document)

assert(heading.attributes[1].specified == true)
assert(heading.attributes[1].name == "id")
assert(heading.attributes[1].localName == "id")

assert(heading.attributes.length == 1)
assert(heading.attributes[1].value == "heading")
assert(heading.attributes.id.value == "heading")
heading.id = "new-id"
assert(heading.attributes.length == 1)
assert(heading.attributes[1].value == "new-id")
assert(heading.attributes.id.value == "new-id")

heading:setAttribute("id", "test...")
assert(heading.attributes.length == 1)
assert(heading.attributes[1].value == "test...")
assert(heading.attributes.id.value == "test...")
heading:setAttribute("new_attr", "new_value")
assert(heading.attributes.length == 2)
assert(heading.attributes[2].value == "new_value")
assert(heading.attributes.new_attr.value == "new_value")

heading.className = "x y z"
assert(heading.attributes.length == 3)
assert(heading.className == "x y z")
assert(heading.attributes[3].value == "x y z")
assert(heading.attributes.class.value == "x y z")

heading:removeAttribute("id")
assert(heading.attributes.length == 2)
assert(not heading.id)
assert(heading.attributes[2].value == "x y z")
heading:removeAttribute("new_attr")
assert(heading.attributes.length == 1)
assert(heading.attributes[1].value == "x y z")
heading:removeAttribute("class")
assert(heading.attributes.length == 0)
assert(not heading.className)
assert(not heading.attributes[1])
assert(not heading.attributes.class)
heading:setAttribute("id", "heading")
assert(heading.attributes.length == 1)
assert(heading:getAttribute("id") == "heading")
heading:setAttribute("foo", "bar")
assert(heading.attributes.length == 2)
assert(heading:getAttribute("foo") == "bar")

assert(heading:hasChildNodes() == true)
assert(heading.childNodes.length == 2)
assert(heading.children.length == 0)
assert(heading.firstChild == heading.childNodes[1])
assert(heading.lastChild == heading.childNodes[2])

heading.firstChild = false
heading.lastChild = "bla"
assert(heading.firstChild == heading.childNodes[1])
assert(heading.lastChild == heading.childNodes[2])

heading.childNodes[2]:remove()
assert(heading:hasChildNodes() == true)
assert(heading.childNodes.length == 1)
assert(heading.firstChild == heading.childNodes[1])
assert(heading.lastChild == heading.childNodes[1])

heading.childNodes[1]:remove()
assert(heading:hasChildNodes() == false)
assert(heading.childNodes.length == 0)
assert(heading.firstChild == nil)
assert(heading.lastChild == nil)

assert(head.parentNode == html)
assert(html:removeChild(head) == head)
assert(head.parentNode == nil)
local status, value = pcall(html.removeChild, html, head)
assert(status == false)
assert(value:find("NotFoundError", 1, true))
assert(html.parentNode == document)
assert(document:removeChild(html) == html)
assert(html.parentNode == nil)
