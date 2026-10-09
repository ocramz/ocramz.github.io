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
            >>= loadAndApplyTemplate "templates/default.html" (openGraphContext defaultContext)
            >>= relativizeUrls

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" (openGraphContext postCtx)
            >>= relativizeUrls

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
                >>= loadAndApplyTemplate "templates/default.html" (openGraphContext archiveCtx)
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
                >>= loadAndApplyTemplate "templates/default.html"
                        (openGraphContext (constField "title" "Marco Zocca" <> indexCtx))
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext


-- | OpenGraph meta tags, rendered into the "opengraph" field of the default template.
--
-- Optional front matter:
--   image: /images/foo.png   (falls back to 'defaultOgImage')
--   description: ...
openGraphContext :: Context String -> Context String
openGraphContext baseCtx =
    openGraphField "opengraph" ctx <> field "twitter-card" twitterCardField <> baseCtx
  where
    ctx = field "og-image" ogImageField
       <> field "og-description" ogDescriptionField
       <> constField "root" siteRoot
       <> baseCtx
    ogImageField item = do
      mImage <- getMetadataField (itemIdentifier item) "image"
      pure $ siteRoot <> maybe defaultOgImage id mImage
    -- large card only for pages with their own (wide) image; the square default
    -- image looks better as a small thumbnail
    twitterCardField item = do
      mImage <- getMetadataField (itemIdentifier item) "image"
      pure $ maybe "summary" (const "summary_large_image") mImage
    ogDescriptionField item =
      getMetadataField (itemIdentifier item) "description" >>= maybe (noResult "no description") pure
    siteRoot = "https://ocramz.github.io"
    defaultOgImage = "/images/me2.jpg"