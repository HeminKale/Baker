You need to think like a architect now. Review below points. Comment your opinion. Add your stuff to make this modern app, interactive app. Analyze the hurdles which may come in early stage. Our framework should be well enough to accommodate even if we add extra functionlity in future.
Couple of things before we start:
    1. We will have multiple UI designs and we can finalize one later. But our backend framework will be same.
    2. We will do tab wise development, with the necessary and required things first, we are builiding from scratch so we need to take care about the strong foundation first.

Now What I see here:
1. We need to decide the tables, Fields (including relationship fields).
2. User should have profile, Roles and Privilage level: Any user who sign up should have default profile of customer and Role: Customer Individual. All these users, profile, Privilage level etc. should be visible to users with admin role only (web app)
3. Each user with role Customer Individual will see there own records.
4. Admin will have access to a settings page: where there are vertical tabs like profile, users, privilage level. Profile will have list of all profiles plus new button, users tab will list all users and a invite user button, privilage level tab will have records of privilage levels with a new privilage level button,  one can create or edit the privilage level, while creating/editing this record user can see the list of objects, on selection of object all fields would display with read and edit checkboxes against it, on selection of edit the read is auto cehcked.
5. These privilage level records can be assigned to Users, so that user will have access to objects and records accordingly.
6. Refer to csv, for Category, Sub-Category, and products in sub-category, there are many things that would get associated with these products like discount, trending, out of stock, etc. we need to think how would we do this. We have images of all products. We need to think to accomodate, the price of each product. We may also need to show original price scracthed out and the discounted price shown.
7. We are planning for tabs like Home, Catalog, Brownie points, Order again, Cart.
8. We do not have all information of what would go in each tab right now. But whatever we have I will provide soon.
9. Let us look at: Order again tab: on click of it we would see, 'Frequently bought together' Where tiles will we shown in horizontal scrolable section, where each tile would have group of items bougth together, images of 2 items will be shown with plus sign in between and then if more items then text like +x itmes. on clcik of the tile just think of opening something may be a popover from bottom covering 85% of screen where items can be scrolled vertically and seen, selected and added to cart too.
here first show the Frequently bought together by user then by others, show top 10 groups scrollable horizontally.
Similarly for previosly bought item section, show the products bought by logged in user earlier in tiles with image, rate, add to cart, then quantity - and + once add to cart is clicked.
10. On Home tab I have no idea what to show.
11. Catalog would show the category, sub category as given in csv and products (not yet added in csv but each sub category would have products), we need to arrange properly the each section of category with horizontal scorl of Sub category tiles. On click of one subcategory item the products in that subcategory shall be displayed on screen with the products tiles in grid on right coveing 95% width on right of screen but the 5% width should be of veritcal scrolling of the subcatecogry in that that category chosen (the demo app has it at top horizontal bar but we want it in the vertical bar on right, we will have multiple UI but this is one example)
12. On click of profile pic on top right, we would see sections one below the other: address, receipts, your orders, profile info, contact us, help and support, log out, Recipes, your wishlist, Order status. In the proper order.
13. We need to plan archtecture on payment methods, Porter Integration.
14. Brownie point tab is still in planning, we can keep it as a placeholder as of now.
15. We will also need rough diagrams (of both app UI and table linked to each other) to understand what our architecture is

Think and add more pooints which need to be taken care of.

Let us develop a architecture first. let us have a concrete plan before we start the android and IOS App