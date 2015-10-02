import Foundation

struct Gravatar {
    private struct Defaults {
        static let scheme = "https"
        static let host = "secure.gravatar.com"
        // unknownHash = md5("unknown@gravatar.com")
        static let unknownHash = "ad516503a11cd5ca435acc9bb6523536"
    }

    let canonicalURL: NSURL

    func urlWithSize(size: Int) -> NSURL {
        let components = NSURLComponents(URL: canonicalURL, resolvingAgainstBaseURL: false)!
        components.query = "s=\(size)&d=404"
        return components.URL!
    }
}

extension Gravatar: Equatable {}

func ==(lhs: Gravatar, rhs: Gravatar) -> Bool {
    return lhs.canonicalURL == rhs.canonicalURL
}

extension Gravatar {
    init?(_ url: NSURL) {
        guard let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        guard let host = components.host
            where host.hasSuffix(".gravatar.com") else {
            return nil
        }

        guard let path = url.path
            where path.hasPrefix("/avatar/") else {
            return nil
        }

        components.scheme = Defaults.scheme
        components.host = Defaults.host
        components.query = nil

        // Treat unknown@gravatar.com as a nil url
        guard let hash = url.lastPathComponent
            where hash != Defaults.unknownHash else {
                return nil
        }

        guard let sanitizedURL = components.URL else {
            return nil
        }

        self.canonicalURL = sanitizedURL
    }
}

extension UIImageView {
    func downloadGravatar(gravatar: Gravatar?, placeholder: UIImage, animate: Bool, failure: ((NSError!) -> ())? = nil) {
        guard let gravatar = gravatar else {
            self.image = placeholder
            return
        }

        let size = Int(ceil(self.frame.width * self.contentScaleFactor))
        let url = gravatar.urlWithSize(size)

        self.downloadImage(url,
            placeholderImage: placeholder,
            success: { (image: UIImage) -> () in
                if animate {
                    self.displayImageWithFadeInAnimation(image)
                }
            }, failure: {
                (error: NSError!) in
                failure?(error)
        })
    }
}