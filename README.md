# LightningSharing
Lightning Components + Apex to implement adhoc sharing in Lightning Experience


## How to use this

1. Make something non public read-write (setup>sharing settings)
2. On that object, add a custom action, select **Lightning Component**, then choose **LightningSharingAction**.
3. Give it a name (**Sharing**) and save
4. Add this actino to the page layout
5. Now when you click the action, you're redirected to the Lightning Sharing component.
6. You can see existing permission on the first tab, and add permissions to users, roles, or groups on the second tab--just type a few letters in and you'll see some results.
7. You can change permissions levels on the first tab (ex: Edit to Read)


## Limitations

* It'll show you all the options--even if the object is ReadOnly, there'll be a button there for Read.  If you click it, you'll get an error.

* If you can't actually set permissions (i.e. you're not the admin or an owner) you'll still have the action button on the page.  Nothing I can do there.  I do, however, prevent you from creating/editing perms that you aren't entitled to
