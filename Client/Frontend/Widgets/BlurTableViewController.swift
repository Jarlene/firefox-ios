/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage

class BlurTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var profile: Profile!
    var site: Site!
    var actions: [BlurTableViewAction] = []
    var tableView = UITableView()
    lazy var tapRecognizer: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(BlurTableViewController.dismiss(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.cancelsTouchesInView = false
        return tapRecognizer
    }()

    lazy var visualEffectView : UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        visualEffectView.frame = self.view.bounds
        visualEffectView.alpha = 0.90
        return visualEffectView
    }()

    lazy var bookmarkAction : BlurTableViewAction = {
        return BlurTableViewAction(title: NSLocalizedString("Bookmark", comment: "Context Menu Action for Activity Stream"), iconString: "action_bookmark", handler: { action in
            let shareItem = ShareItem(url: self.site.url, title: self.site.title, favicon: self.site.icon)
            self.profile.bookmarks.shareItem(shareItem)
            if #available(iOS 9, *) {
                var userData = [QuickActions.TabURLKey: shareItem.url]
                if let title = shareItem.title {
                    userData[QuickActions.TabTitleKey] = title
                }
                QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.OpenLastBookmark,
                    withUserData: userData,
                    toApplication: UIApplication.sharedApplication())
            }
        })
    }()

    lazy var deleteFromHistoryAction : BlurTableViewAction = {
        return BlurTableViewAction(title: NSLocalizedString("Delete from History", comment: "Context Menu Action for Activity Stream"), iconString: "action_delete", handler: { action in
            self.profile.history.removeHistoryForURL(self.site.url)
        })
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.actions = [bookmarkAction, deleteFromHistoryAction]
        view.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.4)

        view.addGestureRecognizer(tapRecognizer)

        view.addSubview(tableView)
        tableView.snp_makeConstraints { make in
            make.center.equalTo(self.view)
            make.width.equalTo(290)
            make.height.equalTo(73 + actions.count * 56)
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.OnDrag
        tableView.backgroundColor = UIConstants.PanelBackgroundColor
        tableView.scrollEnabled = false
        tableView.separatorColor = UIConstants.SeparatorColor
        tableView.layer.cornerRadius = 10
        tableView.registerClass(BlurTableViewCell.self, forCellReuseIdentifier: "BlurTableViewCell")
        tableView.registerClass(BlurTableViewHeaderCell.self, forCellReuseIdentifier: "BlurTableViewHeaderCell")

        if #available(iOS 9, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
    }

    func dismiss(gestureRecognizer: UIGestureRecognizer) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    deinit {
        // The view might outlive this view controller thanks to animations;
        // explicitly nil out its references to us to avoid crashes. Bug 1218826.
        tableView.dataSource = nil
        tableView.delegate = nil
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count + 1
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            return
        }
        let action = actions[indexPath.row - 1]
        return action.handler(action)
    }

    func tableView(tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.row == 0 ? 74 : 56
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("BlurTableViewHeaderCell", forIndexPath: indexPath) as! BlurTableViewHeaderCell
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            cell.configureWithSite(site)
            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier("BlurTableViewCell", forIndexPath: indexPath) as! BlurTableViewCell
        let action = actions[indexPath.row - 1]
        cell.configureCell(action.title, imageString: action.iconString)
        return cell
    }
}

class BlurTableViewHeaderCell: SimpleHighlightCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.mainScreen().scale

        isAccessibilityElement = true

        descriptionLabel.numberOfLines = 1
        titleLabel.numberOfLines = 1

        contentView.addSubview(siteImageView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(titleLabel)

        siteImageView.snp_remakeConstraints { make in
            make.centerY.equalTo(contentView)
            make.leading.equalTo(contentView).offset(12)
            make.size.equalTo(SimpleHighlightCellUX.SiteImageViewSize)
        }

        titleLabel.snp_remakeConstraints { make in
            make.leading.equalTo(siteImageView.snp_trailing).offset(12)
            make.trailing.equalTo(contentView).inset(12)
            make.top.equalTo(siteImageView).offset(8)
        }

        descriptionLabel.snp_remakeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.bottom.equalTo(siteImageView).inset(8)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureWithSite(site: Site) {
        if let icon = site.icon {
            let url = icon.url
            self.siteImageView.layer.borderWidth = 0
            self.setImageWithURL(NSURL(string: url)!)
        } else if let url = NSURL(string: site.url) {
            self.siteImage = FaviconFetcher.getDefaultFavicon(url)
            self.siteImageView.layer.borderWidth = SimpleHighlightCellUX.BorderWidth
        }
        self.titleLabel.text = site.title.characters.count <= 1 ? site.url : site.title
        self.descriptionLabel.text = site.tileURL.baseDomain()
    }
}
