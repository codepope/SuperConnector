//
//  ParseXML.swift
//  SuperConnector
//
//  Borrowed by Dj Walker-Morgan on 22/11/2022.
//  From Paul Hudson's Hacking With Swift

import Foundation

class XMLNode {
    let tag: String
    var data: String
    let attributes: [String: String]
    var childNodes: [XMLNode]

    init(tag: String, data: String, attributes: [String: String], childNodes: [XMLNode]) {
        self.tag = tag
        self.data = data
        self.attributes = attributes
        self.childNodes = childNodes
    }

    func getAttribute(_ name: String) -> String? {
        attributes[name]
    }

    func getElementsByTagName(_ name: String) -> [XMLNode] {
        var results = [XMLNode]()

        for node in childNodes {
            if node.tag == name {
                results.append(node)
            }

            results += node.getElementsByTagName(name)
        }

        return results
    }
}

class MicroDOM: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    private var stack = [XMLNode]()
    private var tree: XMLNode?

    init(data: Data) {
        parser = XMLParser(data: data)
        super.init()
        parser.delegate = self
    }

    func parse() -> XMLNode? {
        parser.parse()

        guard parser.parserError == nil else {
            return nil
        }

        return tree
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        let node = XMLNode(tag: elementName, data: "", attributes: attributeDict, childNodes: [])
        stack.append(node)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let lastElement = stack.removeLast()

        if let last = stack.last {
            last.childNodes += [lastElement]
        } else {
            tree = lastElement
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        stack.last?.data = string
    }
}
