local gumbo = require "gumbo"
local type, assert, pcall = type, assert, pcall
local _ENV = nil

local input = [[
<!DOCTYPE html>
<meta charset=utf-8>
<title>Node.replaceChild</title>
<body><a><b></b><c></c></a>
<div id="log"></div>
]]

local function assertTypeError(func, ...)
    local ok, err = pcall(func, ...)
    if ok then
        error("Expected a TypeError but operation produced no errors", 1)
    elseif type(err) ~= "string" or not err:find("TypeError") then
        error(("Expected a TypeError but got: '%s'"):format(err), 1)
    end
end

local document = assert(gumbo.parse(input))

do -- Passing null to replaceChild should throw a TypeError
    local a = assert(document:createElement("div"))
    assertTypeError(a.replaceChild, a, nil, nil)
    local b = assert(document:createElement("div"))
    assertTypeError(a.replaceChild, a, b, nil)
    assertTypeError(a.replaceChild, a, nil, b)
end

--[[ TODO:

// Step 1.
test(function() {
  var a = document.createElement("div");
  var b = document.createElement("div");
  var c = document.createElement("div");
  assert_throws("NotFoundError", function() {
    a.replaceChild(b, c);
  });

  var d = document.createElement("div");
  d.appendChild(b);
  assert_throws("NotFoundError", function() {
    a.replaceChild(b, c);
  });
  assert_throws("NotFoundError", function() {
    a.replaceChild(b, a);
  });
}, "If child's parent is not the context node, a NotFoundError exception should be thrown")
test(function() {
  var nodes = [
    document.implementation.createDocumentType("html", "", ""),
    document.createTextNode("text"),
    document.implementation.createDocument(null, "foo", null).createProcessingInstruction("foo", "bar"),
    document.createComment("comment")
  ];

  var a = document.createElement("div");
  var b = document.createElement("div");
  nodes.forEach(function(node) {
    assert_throws("HierarchyRequestError", function() {
      node.replaceChild(a, b);
    });
  });
}, "If the context node is not a node that can contain children, a NotFoundError exception should be thrown")

// Step 2.
test(function() {
  var a = document.createElement("div");
  var b = document.createElement("div");

  assert_throws("HierarchyRequestError", function() {
    a.replaceChild(a, a);
  });

  a.appendChild(b);
  assert_throws("HierarchyRequestError", function() {
    a.replaceChild(a, b);
  });

  var c = document.createElement("div");
  c.appendChild(a);
  assert_throws("HierarchyRequestError", function() {
    a.replaceChild(c, b);
  });
}, "If node is an inclusive ancestor of the context node, a HierarchyRequestError should be thrown.")

// Step 3.1.
test(function() {
  var doc = document.implementation.createHTMLDocument("title");
  var doc2 = document.implementation.createHTMLDocument("title2");
  assert_throws("HierarchyRequestError", function() {
    doc.replaceChild(doc2, doc.documentElement);
  });

  assert_throws("HierarchyRequestError", function() {
    doc.replaceChild(doc.createTextNode("text"), doc.documentElement);
  });
}, "If the context node is a document, inserting a document or text node should throw a HierarchyRequestError.")

// Step 3.2.1.
test(function() {
  var doc = document.implementation.createHTMLDocument("title");

  var df = doc.createDocumentFragment();
  df.appendChild(doc.createElement("a"));
  df.appendChild(doc.createElement("b"));
  assert_throws("HierarchyRequestError", function() {
    doc.replaceChild(df, doc.documentElement);
  });

  df = doc.createDocumentFragment();
  df.appendChild(doc.createTextNode("text"));
  assert_throws("HierarchyRequestError", function() {
    doc.replaceChild(df, doc.documentElement);
  });

  df = doc.createDocumentFragment();
  df.appendChild(doc.createComment("comment"));
  df.appendChild(doc.createTextNode("text"));
  assert_throws("HierarchyRequestError", function() {
    doc.replaceChild(df, doc.documentElement);
  });
}, "If the context node is a document, inserting a DocumentFragment that contains a text node or too many elements should throw a HierarchyRequestError.")
test(function() {
  var doc = document.implementation.createHTMLDocument("title");
  doc.removeChild(doc.documentElement);

  var df = doc.createDocumentFragment();
  df.appendChild(doc.createElement("a"));
  df.appendChild(doc.createElement("b"));
  assert_throws("HierarchyRequestError", function() {
    doc.replaceChild(df, doc.doctype);
  });
}, "If the context node is a document (without element children), inserting a DocumentFragment that contains multiple elements should throw a HierarchyRequestError.")

// Step 3.2.2.
test(function() {
  // The context node has an element child that is not /child/.
  var doc = document.implementation.createHTMLDocument("title");
  var comment = doc.appendChild(doc.createComment("foo"));
  assert_array_equals(doc.childNodes, [doc.doctype, doc.documentElement, comment]);

  var df = doc.createDocumentFragment();
  df.appendChild(doc.createElement("a"));
  assert_throws("HierarchyRequestError", function() {
    doc.replaceChild(df, comment);
  });
  assert_throws("HierarchyRequestError", function() {
    doc.replaceChild(df, doc.doctype);
  });
}, "If the context node is a document, inserting a DocumentFragment with an element if there already is an element child should throw a HierarchyRequestError.")
test(function() {
  // A doctype is following /child/.
  var doc = document.implementation.createHTMLDocument("title");
  var comment = doc.insertBefore(doc.createComment("foo"), doc.firstChild);
  doc.removeChild(doc.documentElement);
  assert_array_equals(doc.childNodes, [comment, doc.doctype]);

  var df = doc.createDocumentFragment();
  df.appendChild(doc.createElement("a"));
  assert_throws("HierarchyRequestError", function() {
    doc.replaceChild(df, comment);
  });
}, "If the context node is a document, inserting a DocumentFragment with an element before the doctype should throw a HierarchyRequestError.")

// Step 3.3.
test(function() {
  var doc = document.implementation.createHTMLDocument("title");
  var comment = doc.appendChild(doc.createComment("foo"));
  assert_array_equals(doc.childNodes, [doc.doctype, doc.documentElement, comment]);

  var a = doc.createElement("a");
  assert_throws("HierarchyRequestError", function() {
    doc.replaceChild(a, comment);
  });
  assert_throws("HierarchyRequestError", function() {
    doc.replaceChild(a, doc.doctype);
  });
}, "If the context node is a document, inserting an element if there already is an element child should throw a HierarchyRequestError.")
test(function() {
  var doc = document.implementation.createHTMLDocument("title");
  var comment = doc.insertBefore(doc.createComment("foo"), doc.firstChild);
  doc.removeChild(doc.documentElement);
  assert_array_equals(doc.childNodes, [comment, doc.doctype]);

  var a = doc.createElement("a");
  assert_throws("HierarchyRequestError", function() {
    doc.replaceChild(a, comment);
  });
}, "If the context node is a document, inserting an element before the doctype should throw a HierarchyRequestError.")

// Step 3.4.
test(function() {
  var doc = document.implementation.createHTMLDocument("title");
  var comment = doc.insertBefore(doc.createComment("foo"), doc.firstChild);
  assert_array_equals(doc.childNodes, [comment, doc.doctype, doc.documentElement]);

  var doctype = document.implementation.createDocumentType("html", "", "");
  assert_throws("HierarchyRequestError", function() {
    doc.replaceChild(doctype, comment);
  });
  assert_throws("HierarchyRequestError", function() {
    doc.replaceChild(doctype, doc.documentElement);
  });
}, "If the context node is a document, inserting a doctype if there already is a doctype child should throw a HierarchyRequestError.")
test(function() {
  var doc = document.implementation.createHTMLDocument("title");
  var comment = doc.appendChild(doc.createComment("foo"));
  doc.removeChild(doc.doctype);
  assert_array_equals(doc.childNodes, [doc.documentElement, comment]);

  var doctype = document.implementation.createDocumentType("html", "", "");
  assert_throws("HierarchyRequestError", function() {
    doc.replaceChild(doctype, comment);
  });
}, "If the context node is a document, inserting a doctype after the document element should throw a HierarchyRequestError.")

// Step 4.
test(function() {
  var df = document.createDocumentFragment();
  var a = df.appendChild(document.createElement("a"));

  var doc = document.implementation.createHTMLDocument("title");
  assert_throws("HierarchyRequestError", function() {
    df.replaceChild(doc, a);
  });

  var doctype = document.implementation.createDocumentType("html", "", "");
  assert_throws("HierarchyRequestError", function() {
    df.replaceChild(doctype, a);
  });
}, "If the context node is a DocumentFragment, inserting a document or a doctype should throw a HierarchyRequestError.")
test(function() {
  var el = document.createElement("div");
  var a = el.appendChild(document.createElement("a"));

  var doc = document.implementation.createHTMLDocument("title");
  assert_throws("HierarchyRequestError", function() {
    el.replaceChild(doc, a);
  });

  var doctype = document.implementation.createDocumentType("html", "", "");
  assert_throws("HierarchyRequestError", function() {
    el.replaceChild(doctype, a);
  });
}, "If the context node is an element, inserting a document or a doctype should throw a HierarchyRequestError.")

// Step 6.
test(function() {
  var a = document.createElement("div");
  var b = document.createElement("div");
  var c = document.createElement("div");
  a.appendChild(b);
  a.appendChild(c);
  assert_array_equals(a.childNodes, [b, c]);
  assert_equals(a.replaceChild(c, b), b);
  assert_array_equals(a.childNodes, [c]);
}, "Replacing a node with its next sibling should work (2 children)");
test(function() {
  var a = document.createElement("div");
  var b = document.createElement("div");
  var c = document.createElement("div");
  var d = document.createElement("div");
  var e = document.createElement("div");
  a.appendChild(b);
  a.appendChild(c);
  a.appendChild(d);
  a.appendChild(e);
  assert_array_equals(a.childNodes, [b, c, d, e]);
  assert_equals(a.replaceChild(d, c), c);
  assert_array_equals(a.childNodes, [b, d, e]);
}, "Replacing a node with its next sibling should work (4 children)");
test(function() {
  var a = document.createElement("div");
  var b = document.createElement("div");
  var c = document.createElement("div");
  a.appendChild(b);
  a.appendChild(c);
  assert_array_equals(a.childNodes, [b, c]);
  assert_equals(a.replaceChild(b, b), b);
  assert_array_equals(a.childNodes, [b, c]);
  assert_equals(a.replaceChild(c, c), c);
  assert_array_equals(a.childNodes, [b, c]);
}, "Replacing a node with itself should not move the node");

// Step 7.
test(function() {
  var doc = document.implementation.createHTMLDocument("title");
  var doctype = doc.doctype;
  assert_array_equals(doc.childNodes, [doctype, doc.documentElement]);

  var doc2 = document.implementation.createHTMLDocument("title2");
  var doctype2 = doc2.doctype;
  assert_array_equals(doc2.childNodes, [doctype2, doc2.documentElement]);

  doc.replaceChild(doc2.doctype, doc.doctype);
  assert_array_equals(doc.childNodes, [doctype2, doc.documentElement]);
  assert_array_equals(doc2.childNodes, [doc2.documentElement]);
  assert_equals(doctype.parentNode, null);
  assert_equals(doctype.ownerDocument, doc);
  assert_equals(doctype2.parentNode, doc);
  assert_equals(doctype2.ownerDocument, doc);
}, "If the context node is a document, inserting a new doctype should work.")

// Bugs.
test(function() {
  var doc = document.implementation.createHTMLDocument("title");
  var df = doc.createDocumentFragment();
  var a = df.appendChild(doc.createElement("a"));
  assert_equals(doc.documentElement, doc.replaceChild(df, doc.documentElement));
  assert_array_equals(doc.childNodes, [doc.doctype, a]);
}, "Replacing the document element with a DocumentFragment containing a single element should work.");
test(function() {
  var doc = document.implementation.createHTMLDocument("title");
  var df = doc.createDocumentFragment();
  var a = df.appendChild(doc.createComment("a"));
  var b = df.appendChild(doc.createElement("b"));
  var c = df.appendChild(doc.createComment("c"));
  assert_equals(doc.documentElement, doc.replaceChild(df, doc.documentElement));
  assert_array_equals(doc.childNodes, [doc.doctype, a, b, c]);
}, "Replacing the document element with a DocumentFragment containing a single element and comments should work.");
test(function() {
  var doc = document.implementation.createHTMLDocument("title");
  var a = doc.createElement("a");
  assert_equals(doc.documentElement, doc.replaceChild(a, doc.documentElement));
  assert_array_equals(doc.childNodes, [doc.doctype, a]);
}, "Replacing the document element with a single element should work.");
test(function() {
  document.addEventListener("DOMNodeRemoved", function(e) {
    document.body.appendChild(document.createElement("x"));
  }, false);
  var a = document.body.firstChild, b = a.firstChild, c = b.nextSibling;
  assert_equals(a.replaceChild(c, b), b);
  assert_equals(b.parentNode, null);
  assert_equals(a.firstChild, c);
  assert_equals(c.parentNode, a);
}, "replaceChild should work in the presence of mutation events.")
test(function() {
  var TEST_ID = "findme";
  var gBody = document.getElementsByTagName("body")[0];
  var parent = document.createElement("div");
  gBody.appendChild(parent);
  var child = document.createElement("div");
  parent.appendChild(child);
  var df = document.createDocumentFragment();
  var fragChild = df.appendChild(document.createElement("div"));
  fragChild.setAttribute("id", TEST_ID);
  parent.replaceChild(df, child);
  assert_equals(document.getElementById(TEST_ID), fragChild, "should not be null");
}, "Replacing an element with a DocumentFragment should allow a child of the DocumentFragment to be found by Id.")
</script>
]]
