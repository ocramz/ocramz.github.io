--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll

import Text.Pandoc.Highlighting (Style, tango, styleToCss)
import Text.Pandoc.Options      (ReaderOptions(..), WriterOptions(..), HTMLMathMethod(..))

import Hakyll.Web.Meta.OpenGraph (openGraphField)


--------------------------------------------------------------------------------

-- rendered website will appear in the docs/ subdirectory
cfg = defaultConfiguration {
  destinationDirectory = "docs"
}

-- pandocCodeStyle :: Style
-- pandocCodeStyle = tango

-- -- enable syntax highlighting
-- pandocCompiler' :: Compiler (Item String)
-- pandocCompiler' =
--   pandocCompilerWith
--     defaultHakyllReaderOptions
--     defaultHakyllWriterOptions
--       { writerHighlightStyle   = Just pandocCodeStyle
--       }


writerOptions = defaultHakyllWriterOptions
                    { writerHTMLMathMethod = MathJax "" }

pandocCompilerWithMathJax = pandocCompilerWith defaultHakyllReaderOptions writerOptions

main :: IO ()
main = hakyllWith cfg $ do
    -- create ["css/syntax.css"] $ do
    --     route idRoute
    --     compile $ do
    --         makeItem $ styleToCss pandocCodeStyle

    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "js/*" $ do
        route   idRoute
        compile copyFileCompiler

    match (fromList ["about.html", "contact.markdown", "oss.html", "research.html"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" (postCtx <> openGraphContext)
            -- >>= relativizeUrls

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Posts"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls


    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" ""            `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext


openGraphContext :: Context String
openGraphContext = openGraphField "opengraph" ctx
  where
    ctx = field "og-image" ogImageField <> constField "root" siteRoot <> defaultContext
    ogImageField item = do
      Just path <- getRoute $ setVersion (Just "og-image") (itemIdentifier item)
      pure $ siteRoot <> toUrl path
    siteRoot = "https://ocramz.github.io"