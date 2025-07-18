import { SitemapStream, streamToPromise } from "sitemap";
import { createWriteStream } from "fs";

const sitemap = new SitemapStream({ hostname: "https://ulishastore.com" });
const writeStream = createWriteStream("./public/sitemap.xml");

sitemap.pipe(writeStream);

sitemap.write({ url: "/", changefreq: "daily", priority: 1.0 });
sitemap.write({ url: "/login", changefreq: "weekly", priority: 0.8 });
sitemap.write({ url: "/register", changefreq: "weekly", priority: 0.8 });
sitemap.write({ url: "/terms", changefreq: "weekly", priority: 0.8 });
sitemap.write({ url: "/returns", changefreq: "weekly", priority: 0.8 });
sitemap.write({ url: "/search", changefreq: "weekly", priority: 0.8 });
sitemap.write({ url: "/chat-support", changefreq: "weekly", priority: 0.8 });

/*
 * Categories
 * These categories are used in the application and should be kept in sync with the actual categories.
 * If a category is removed from the application, it should also be removed from this sitemap.
 * If a new category is added, it should be added here as well.
 */
const categories = [
    "clothes",
    "jewelries",
    "accessories",
    "eletronics",
    "smart-watches",
    "shoes",
    "phones",
    "gym-wear",
    "handbags",
    "perfumes-body-spray",
];

for (const category of categories) {
    sitemap.write({
        url: `/categories/${category}`,
        changefreq: "daily",
        priority: 0.8,
    });
}

sitemap.end();

streamToPromise(sitemap).then(() => console.log("Sitemap written."));
