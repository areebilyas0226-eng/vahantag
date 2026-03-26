require("dotenv").config();
const { Pool } = require("pg");
const { v4: uuidv4 } = require("uuid");
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const seed = async () => {
  console.log("Seeding asset categories...");
  await pool.query("DELETE FROM asset_categories");
  const cats = [
    { name: "Vehicle", icon: "🚗", slug: "vehicle", description: "Cars, bikes, trucks, scooters", yearly: 49900, renewal: 29900, order: 1 },
    { name: "Pet", icon: "🐕", slug: "pet", description: "Dogs, cats, birds and other pets", yearly: 29900, renewal: 19900, order: 2 },
    { name: "Bag / Luggage", icon: "👜", slug: "bag", description: "Bags, suitcases, backpacks", yearly: 19900, renewal: 9900, order: 3 },
    { name: "Phone / Laptop", icon: "📱", slug: "electronics", description: "Mobile phones, laptops, tablets", yearly: 19900, renewal: 9900, order: 4 },
    { name: "Keys", icon: "🔑", slug: "keys", description: "House keys, car keys, office keys", yearly: 19900, renewal: 9900, order: 5 },
    { name: "Other Asset", icon: "📦", slug: "other", description: "Any other valuable asset", yearly: 19900, renewal: 9900, order: 6 },
  ];
  for (const c of cats) {
    await pool.query(
      "INSERT INTO asset_categories (id, name, icon, slug, description, yearly_price_paisa, renewal_price_paisa, is_active, sort_order) VALUES ($1,$2,$3,$4,$5,$6,$7,true,$8)",
      [uuidv4(), c.name, c.icon, c.slug, c.description, c.yearly, c.renewal, c.order]
    );
    console.log("Added category:", c.name, "- Yearly: Rs." + c.yearly/100);
  }
  console.log("Seeding complete!");
  process.exit(0);
};
seed().catch(e => { console.error(e.message); process.exit(1); });
