import UIKit

class SegueSlideDown: UIStoryboardSegue
{
    override func perform()
    {
        let src = self.source
        let dst = self.destination
        
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: 0, y: src.view.frame.size.height)
        UIView.animate(
            withDuration: 0.4,
            delay: 0.0,
            options: [],
            animations: {
                dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
                src.view.transform = CGAffineTransform(translationX: 0, y: -src.view.frame.size.height)
            },
            completion: { finished in src.present(dst, animated: false, completion: nil)}
        )
    }
}


class SegueSlideUp: UIStoryboardSegue
{
    override func perform()
    {
        let src = self.source
        let dst = self.destination
        
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: 0, y: -src.view.frame.size.height)
        UIView.animate(
            withDuration: 0.4,
            delay: 0.0,
            options: [],
            animations: {
                dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
                src.view.transform = CGAffineTransform(translationX: 0, y: src.view.frame.size.height)
        },
            completion: { finished in src.present(dst, animated: false, completion: nil)}
        )
    }
}
