create table "public"."advertisements" (
    "id" uuid not null default gen_random_uuid(),
    "title" text not null,
    "description" text not null,
    "image_url" text not null,
    "button_text" text not null,
    "button_link" text not null,
    "active" boolean default true,
    "created_at" timestamp with time zone default now()
);


alter table "public"."advertisements" enable row level security;

create table "public"."affiliate_accounts" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "referral_code" text not null,
    "earnings" numeric default 0,
    "paid_earnings" numeric default 0,
    "status" text default 'pending'::text,
    "payment_details" jsonb default '{}'::jsonb,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "referral_count" integer default 0
);


alter table "public"."affiliate_accounts" enable row level security;

create table "public"."affiliate_commissions" (
    "id" uuid not null default gen_random_uuid(),
    "affiliate_id" uuid not null,
    "order_id" uuid not null,
    "amount" numeric not null,
    "status" text default 'pending'::text,
    "created_at" timestamp with time zone default now()
);


alter table "public"."affiliate_commissions" enable row level security;

create table "public"."affiliate_referrals" (
    "id" uuid not null default gen_random_uuid(),
    "referrer_id" uuid not null,
    "referred_user_id" uuid not null,
    "status" text default 'active'::text,
    "created_at" timestamp with time zone default now()
);


alter table "public"."affiliate_referrals" enable row level security;

create table "public"."affiliate_settings" (
    "id" uuid not null default gen_random_uuid(),
    "commission_rate" numeric not null default 10.0,
    "min_payout" numeric not null default 5000.0,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."affiliate_settings" enable row level security;

create table "public"."analytics_daily_stats" (
    "id" uuid not null default gen_random_uuid(),
    "date" date not null,
    "unique_visitors" integer default 0,
    "page_views" integer default 0,
    "new_users" integer default 0,
    "orders_count" integer default 0,
    "revenue" numeric default 0,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."analytics_daily_stats" enable row level security;

create table "public"."analytics_page_views" (
    "id" uuid not null default gen_random_uuid(),
    "session_id" text not null,
    "user_id" uuid,
    "page_path" text not null,
    "user_agent" text,
    "ip_address" text,
    "referrer" text,
    "created_at" timestamp with time zone default now()
);


alter table "public"."analytics_page_views" enable row level security;

create table "public"."app_settings" (
    "id" uuid not null default gen_random_uuid(),
    "logo_url" text not null,
    "favicon_url" text not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."app_settings" enable row level security;

create table "public"."cart_items" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "product_id" uuid not null,
    "quantity" integer not null default 1,
    "created_at" timestamp with time zone default now()
);


alter table "public"."cart_items" enable row level security;

create table "public"."cart_items_new" (
    "id" uuid not null default gen_random_uuid(),
    "session_id" uuid,
    "product_id" uuid,
    "quantity" integer not null default 1,
    "price_snapshot" numeric not null,
    "is_saved_for_later" boolean default false,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "variant_id" uuid,
    "selected_color" text,
    "selected_size" text
);


alter table "public"."cart_items_new" enable row level security;

create table "public"."order_items" (
    "id" uuid not null default gen_random_uuid(),
    "order_id" uuid not null,
    "product_id" uuid not null,
    "quantity" integer not null default 1,
    "price" numeric not null,
    "created_at" timestamp with time zone default now(),
    "variant_id" uuid,
    "selected_color" text,
    "selected_size" text,
    "delivery_type" text default 'standard'::text
);


alter table "public"."order_items" enable row level security;

create table "public"."orders" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "total" numeric not null default 0,
    "status" text not null default 'pending'::text,
    "created_at" timestamp with time zone default now(),
    "delivery_address" text,
    "delivery_phone" text,
    "delivery_name" text,
    "payment_ref" text,
    "payment_method" text
);


alter table "public"."orders" enable row level security;

create table "public"."product_images" (
    "id" uuid not null default gen_random_uuid(),
    "product_id" uuid,
    "image_url" text not null,
    "created_at" timestamp with time zone default now()
);


alter table "public"."product_images" enable row level security;

create table "public"."product_ratings" (
    "id" uuid not null default gen_random_uuid(),
    "product_id" uuid,
    "user_id" uuid,
    "rating" integer not null,
    "created_at" timestamp with time zone default now()
);


alter table "public"."product_ratings" enable row level security;

create table "public"."product_variants" (
    "id" uuid not null default gen_random_uuid(),
    "product_id" uuid,
    "color" text not null,
    "size" text not null,
    "stock" integer not null default 0,
    "created_at" timestamp with time zone default now()
);


alter table "public"."product_variants" enable row level security;

create table "public"."products" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "price" numeric not null,
    "category" text not null,
    "description" text not null,
    "image" text not null,
    "created_at" timestamp with time zone default now(),
    "store_id" uuid,
    "seller_id" uuid,
    "seller_phone" text,
    "rating" numeric default 5,
    "original_price" numeric,
    "discount_price" numeric,
    "discount_active" boolean default false,
    "discount_percentage" numeric generated always as (
CASE
    WHEN ((original_price > (0)::numeric) AND (discount_price > (0)::numeric)) THEN round((((1)::numeric - (discount_price / original_price)) * (100)::numeric))
    ELSE (0)::numeric
END) stored,
    "shipping_location" text not null default 'Nigeria'::text
);


alter table "public"."products" enable row level security;

create table "public"."shopping_sessions" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "status" text default 'active'::text
);


alter table "public"."shopping_sessions" enable row level security;

create table "public"."stores" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "description" text,
    "logo" text not null,
    "banner" text not null,
    "phone" text not null,
    "address" text not null,
    "user_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "store_url" text not null
);


alter table "public"."stores" enable row level security;

create table "public"."user_preferences" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid,
    "currency" text not null default 'NGN'::text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."user_preferences" enable row level security;

create table "public"."users" (
    "id" uuid not null default gen_random_uuid(),
    "firebase_uid" text not null,
    "email" text not null,
    "full_name" text,
    "avatar_url" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."users" enable row level security;

CREATE UNIQUE INDEX advertisements_pkey ON public.advertisements USING btree (id);

CREATE UNIQUE INDEX affiliate_accounts_pkey ON public.affiliate_accounts USING btree (id);

CREATE UNIQUE INDEX affiliate_accounts_referral_code_key ON public.affiliate_accounts USING btree (referral_code);

CREATE UNIQUE INDEX affiliate_accounts_user_id_key ON public.affiliate_accounts USING btree (user_id);

CREATE UNIQUE INDEX affiliate_commissions_pkey ON public.affiliate_commissions USING btree (id);

CREATE UNIQUE INDEX affiliate_referrals_pkey ON public.affiliate_referrals USING btree (id);

CREATE UNIQUE INDEX affiliate_referrals_referred_user_id_key ON public.affiliate_referrals USING btree (referred_user_id);

CREATE UNIQUE INDEX affiliate_settings_pkey ON public.affiliate_settings USING btree (id);

CREATE UNIQUE INDEX analytics_daily_stats_date_key ON public.analytics_daily_stats USING btree (date);

CREATE UNIQUE INDEX analytics_daily_stats_pkey ON public.analytics_daily_stats USING btree (id);

CREATE UNIQUE INDEX analytics_page_views_pkey ON public.analytics_page_views USING btree (id);

CREATE UNIQUE INDEX app_settings_pkey ON public.app_settings USING btree (id);

CREATE UNIQUE INDEX cart_items_new_pkey ON public.cart_items_new USING btree (id);

CREATE UNIQUE INDEX cart_items_new_session_id_product_id_key ON public.cart_items_new USING btree (session_id, product_id);

CREATE UNIQUE INDEX cart_items_pkey ON public.cart_items USING btree (id);

CREATE UNIQUE INDEX cart_items_user_id_product_id_key ON public.cart_items USING btree (user_id, product_id);

CREATE INDEX idx_advertisements_active_created ON public.advertisements USING btree (active, created_at DESC);

CREATE INDEX idx_affiliate_accounts_referral_code ON public.affiliate_accounts USING btree (referral_code);

CREATE INDEX idx_affiliate_accounts_user_id ON public.affiliate_accounts USING btree (user_id);

CREATE INDEX idx_affiliate_commissions_affiliate_id ON public.affiliate_commissions USING btree (affiliate_id);

CREATE INDEX idx_affiliate_referrals_referred_user_id ON public.affiliate_referrals USING btree (referred_user_id);

CREATE INDEX idx_affiliate_referrals_referrer_id ON public.affiliate_referrals USING btree (referrer_id);

CREATE INDEX idx_analytics_daily_stats_date ON public.analytics_daily_stats USING btree (date DESC);

CREATE INDEX idx_analytics_page_views_created_at ON public.analytics_page_views USING btree (created_at DESC);

CREATE INDEX idx_analytics_page_views_session_id ON public.analytics_page_views USING btree (session_id);

CREATE INDEX idx_analytics_page_views_user_id ON public.analytics_page_views USING btree (user_id);

CREATE INDEX idx_cart_items_new_product_id ON public.cart_items_new USING btree (product_id);

CREATE INDEX idx_cart_items_new_session_id ON public.cart_items_new USING btree (session_id);

CREATE INDEX idx_cart_items_new_variant_id ON public.cart_items_new USING btree (variant_id);

CREATE INDEX idx_cart_items_variant_lookup ON public.cart_items_new USING btree (variant_id, selected_color, selected_size);

CREATE INDEX idx_order_items_delivery_type ON public.order_items USING btree (delivery_type);

CREATE INDEX idx_order_items_order_id ON public.order_items USING btree (order_id);

CREATE INDEX idx_order_items_order_product ON public.order_items USING btree (order_id, product_id);

CREATE INDEX idx_order_items_variant_id ON public.order_items USING btree (variant_id);

CREATE INDEX idx_order_items_variant_lookup ON public.order_items USING btree (variant_id, selected_color, selected_size);

CREATE INDEX idx_orders_created_at ON public.orders USING btree (created_at DESC);

CREATE INDEX idx_orders_payment_ref ON public.orders USING btree (payment_ref);

CREATE INDEX idx_orders_payment_ref_status ON public.orders USING btree (payment_ref, status) WHERE ((payment_ref IS NOT NULL) AND (payment_ref <> 'pending'::text));

CREATE INDEX idx_orders_user_id ON public.orders USING btree (user_id);

CREATE INDEX idx_orders_user_status_created ON public.orders USING btree (user_id, status, created_at DESC);

CREATE INDEX idx_product_images_product_id ON public.product_images USING btree (product_id);

CREATE INDEX idx_product_ratings_product_id ON public.product_ratings USING btree (product_id);

CREATE INDEX idx_product_ratings_user_id ON public.product_ratings USING btree (user_id);

CREATE INDEX idx_product_variants_color_size ON public.product_variants USING btree (color, size);

CREATE INDEX idx_product_variants_product_id ON public.product_variants USING btree (product_id);

CREATE INDEX idx_products_category ON public.products USING btree (category);

CREATE INDEX idx_products_created_at ON public.products USING btree (created_at DESC);

CREATE INDEX idx_products_seller_id ON public.products USING btree (seller_id);

CREATE INDEX idx_products_shipping_location ON public.products USING btree (shipping_location);

CREATE INDEX idx_products_store_id ON public.products USING btree (store_id);

CREATE INDEX idx_shopping_sessions_user_id ON public.shopping_sessions USING btree (user_id);

CREATE INDEX idx_shopping_sessions_user_id_status ON public.shopping_sessions USING btree (user_id, status);

CREATE INDEX idx_stores_user_id ON public.stores USING btree (user_id);

CREATE INDEX idx_users_email ON public.users USING btree (email);

CREATE INDEX idx_users_firebase_uid ON public.users USING btree (firebase_uid);

CREATE UNIQUE INDEX order_items_pkey ON public.order_items USING btree (id);

CREATE UNIQUE INDEX orders_pkey ON public.orders USING btree (id);

CREATE UNIQUE INDEX product_images_pkey ON public.product_images USING btree (id);

CREATE UNIQUE INDEX product_ratings_pkey ON public.product_ratings USING btree (id);

CREATE UNIQUE INDEX product_ratings_product_id_user_id_key ON public.product_ratings USING btree (product_id, user_id);

CREATE UNIQUE INDEX product_variants_pkey ON public.product_variants USING btree (id);

CREATE UNIQUE INDEX product_variants_product_id_color_size_key ON public.product_variants USING btree (product_id, color, size);

CREATE UNIQUE INDEX products_pkey ON public.products USING btree (id);

CREATE UNIQUE INDEX shopping_sessions_pkey ON public.shopping_sessions USING btree (id);

CREATE UNIQUE INDEX stores_pkey ON public.stores USING btree (id);

CREATE UNIQUE INDEX unique_active_session ON public.shopping_sessions USING btree (user_id, status);

CREATE UNIQUE INDEX unique_store_url ON public.stores USING btree (store_url);

CREATE UNIQUE INDEX user_preferences_pkey ON public.user_preferences USING btree (id);

CREATE UNIQUE INDEX user_preferences_user_id_key ON public.user_preferences USING btree (user_id);

CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email);

CREATE UNIQUE INDEX users_firebase_uid_key ON public.users USING btree (firebase_uid);

CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id);

alter table "public"."advertisements" add constraint "advertisements_pkey" PRIMARY KEY using index "advertisements_pkey";

alter table "public"."affiliate_accounts" add constraint "affiliate_accounts_pkey" PRIMARY KEY using index "affiliate_accounts_pkey";

alter table "public"."affiliate_commissions" add constraint "affiliate_commissions_pkey" PRIMARY KEY using index "affiliate_commissions_pkey";

alter table "public"."affiliate_referrals" add constraint "affiliate_referrals_pkey" PRIMARY KEY using index "affiliate_referrals_pkey";

alter table "public"."affiliate_settings" add constraint "affiliate_settings_pkey" PRIMARY KEY using index "affiliate_settings_pkey";

alter table "public"."analytics_daily_stats" add constraint "analytics_daily_stats_pkey" PRIMARY KEY using index "analytics_daily_stats_pkey";

alter table "public"."analytics_page_views" add constraint "analytics_page_views_pkey" PRIMARY KEY using index "analytics_page_views_pkey";

alter table "public"."app_settings" add constraint "app_settings_pkey" PRIMARY KEY using index "app_settings_pkey";

alter table "public"."cart_items" add constraint "cart_items_pkey" PRIMARY KEY using index "cart_items_pkey";

alter table "public"."cart_items_new" add constraint "cart_items_new_pkey" PRIMARY KEY using index "cart_items_new_pkey";

alter table "public"."order_items" add constraint "order_items_pkey" PRIMARY KEY using index "order_items_pkey";

alter table "public"."orders" add constraint "orders_pkey" PRIMARY KEY using index "orders_pkey";

alter table "public"."product_images" add constraint "product_images_pkey" PRIMARY KEY using index "product_images_pkey";

alter table "public"."product_ratings" add constraint "product_ratings_pkey" PRIMARY KEY using index "product_ratings_pkey";

alter table "public"."product_variants" add constraint "product_variants_pkey" PRIMARY KEY using index "product_variants_pkey";

alter table "public"."products" add constraint "products_pkey" PRIMARY KEY using index "products_pkey";

alter table "public"."shopping_sessions" add constraint "shopping_sessions_pkey" PRIMARY KEY using index "shopping_sessions_pkey";

alter table "public"."stores" add constraint "stores_pkey" PRIMARY KEY using index "stores_pkey";

alter table "public"."user_preferences" add constraint "user_preferences_pkey" PRIMARY KEY using index "user_preferences_pkey";

alter table "public"."users" add constraint "users_pkey" PRIMARY KEY using index "users_pkey";

alter table "public"."affiliate_accounts" add constraint "affiliate_accounts_referral_code_key" UNIQUE using index "affiliate_accounts_referral_code_key";

alter table "public"."affiliate_accounts" add constraint "affiliate_accounts_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."affiliate_accounts" validate constraint "affiliate_accounts_user_id_fkey";

alter table "public"."affiliate_accounts" add constraint "affiliate_accounts_user_id_key" UNIQUE using index "affiliate_accounts_user_id_key";

alter table "public"."affiliate_commissions" add constraint "affiliate_commissions_affiliate_id_fkey" FOREIGN KEY (affiliate_id) REFERENCES affiliate_accounts(id) not valid;

alter table "public"."affiliate_commissions" validate constraint "affiliate_commissions_affiliate_id_fkey";

alter table "public"."affiliate_commissions" add constraint "affiliate_commissions_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id) not valid;

alter table "public"."affiliate_commissions" validate constraint "affiliate_commissions_order_id_fkey";

alter table "public"."affiliate_referrals" add constraint "affiliate_referrals_referred_user_id_fkey" FOREIGN KEY (referred_user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."affiliate_referrals" validate constraint "affiliate_referrals_referred_user_id_fkey";

alter table "public"."affiliate_referrals" add constraint "affiliate_referrals_referred_user_id_key" UNIQUE using index "affiliate_referrals_referred_user_id_key";

alter table "public"."affiliate_referrals" add constraint "affiliate_referrals_referrer_id_fkey" FOREIGN KEY (referrer_id) REFERENCES affiliate_accounts(id) not valid;

alter table "public"."affiliate_referrals" validate constraint "affiliate_referrals_referrer_id_fkey";

alter table "public"."analytics_daily_stats" add constraint "analytics_daily_stats_date_key" UNIQUE using index "analytics_daily_stats_date_key";

alter table "public"."analytics_page_views" add constraint "analytics_page_views_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."analytics_page_views" validate constraint "analytics_page_views_user_id_fkey";

alter table "public"."cart_items" add constraint "cart_items_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."cart_items" validate constraint "cart_items_user_id_fkey";

alter table "public"."cart_items" add constraint "cart_items_user_id_product_id_key" UNIQUE using index "cart_items_user_id_product_id_key";

alter table "public"."cart_items" add constraint "fk_cart_items_product" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE not valid;

alter table "public"."cart_items" validate constraint "fk_cart_items_product";

alter table "public"."cart_items_new" add constraint "cart_items_new_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE not valid;

alter table "public"."cart_items_new" validate constraint "cart_items_new_product_id_fkey";

alter table "public"."cart_items_new" add constraint "cart_items_new_session_id_fkey" FOREIGN KEY (session_id) REFERENCES shopping_sessions(id) ON DELETE CASCADE not valid;

alter table "public"."cart_items_new" validate constraint "cart_items_new_session_id_fkey";

alter table "public"."cart_items_new" add constraint "cart_items_new_session_id_product_id_key" UNIQUE using index "cart_items_new_session_id_product_id_key";

alter table "public"."cart_items_new" add constraint "cart_items_new_variant_id_fkey" FOREIGN KEY (variant_id) REFERENCES product_variants(id) not valid;

alter table "public"."cart_items_new" validate constraint "cart_items_new_variant_id_fkey";

alter table "public"."cart_items_new" add constraint "check_cart_quantity_positive" CHECK ((quantity > 0)) not valid;

alter table "public"."cart_items_new" validate constraint "check_cart_quantity_positive";

alter table "public"."cart_items_new" add constraint "check_variant_data" CHECK ((((variant_id IS NOT NULL) AND (selected_color IS NOT NULL) AND (selected_size IS NOT NULL)) OR ((variant_id IS NULL) AND (selected_color IS NULL) AND (selected_size IS NULL)))) not valid;

alter table "public"."cart_items_new" validate constraint "check_variant_data";

alter table "public"."order_items" add constraint "check_delivery_type" CHECK ((delivery_type = ANY (ARRAY['standard'::text, 'express'::text]))) not valid;

alter table "public"."order_items" validate constraint "check_delivery_type";

alter table "public"."order_items" add constraint "check_quantity_positive" CHECK ((quantity > 0)) not valid;

alter table "public"."order_items" validate constraint "check_quantity_positive";

alter table "public"."order_items" add constraint "check_variant_data" CHECK ((((variant_id IS NOT NULL) AND (selected_color IS NOT NULL) AND (selected_size IS NOT NULL)) OR ((variant_id IS NULL) AND (selected_color IS NULL) AND (selected_size IS NULL)))) not valid;

alter table "public"."order_items" validate constraint "check_variant_data";

alter table "public"."order_items" add constraint "fk_order_items_product" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE not valid;

alter table "public"."order_items" validate constraint "fk_order_items_product";

alter table "public"."order_items" add constraint "order_items_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id) not valid;

alter table "public"."order_items" validate constraint "order_items_order_id_fkey";

alter table "public"."order_items" add constraint "order_items_variant_id_fkey" FOREIGN KEY (variant_id) REFERENCES product_variants(id) not valid;

alter table "public"."order_items" validate constraint "order_items_variant_id_fkey";

alter table "public"."orders" add constraint "check_total_positive" CHECK ((total >= (0)::numeric)) not valid;

alter table "public"."orders" validate constraint "check_total_positive";

alter table "public"."orders" add constraint "orders_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."orders" validate constraint "orders_user_id_fkey";

alter table "public"."product_images" add constraint "product_images_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE not valid;

alter table "public"."product_images" validate constraint "product_images_product_id_fkey";

alter table "public"."product_ratings" add constraint "product_ratings_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE not valid;

alter table "public"."product_ratings" validate constraint "product_ratings_product_id_fkey";

alter table "public"."product_ratings" add constraint "product_ratings_product_id_user_id_key" UNIQUE using index "product_ratings_product_id_user_id_key";

alter table "public"."product_ratings" add constraint "product_ratings_rating_check" CHECK (((rating >= 1) AND (rating <= 5))) not valid;

alter table "public"."product_ratings" validate constraint "product_ratings_rating_check";

alter table "public"."product_ratings" add constraint "product_ratings_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."product_ratings" validate constraint "product_ratings_user_id_fkey";

alter table "public"."product_variants" add constraint "product_variants_product_id_color_size_key" UNIQUE using index "product_variants_product_id_color_size_key";

alter table "public"."product_variants" add constraint "product_variants_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE not valid;

alter table "public"."product_variants" validate constraint "product_variants_product_id_fkey";

alter table "public"."products" add constraint "check_discount_price" CHECK (((discount_price IS NULL) OR ((discount_price > (0)::numeric) AND (discount_price < original_price)))) not valid;

alter table "public"."products" validate constraint "check_discount_price";

alter table "public"."products" add constraint "check_shipping_location" CHECK ((shipping_location = ANY (ARRAY['Nigeria'::text, 'Abroad'::text]))) not valid;

alter table "public"."products" validate constraint "check_shipping_location";

alter table "public"."products" add constraint "products_seller_id_fkey" FOREIGN KEY (seller_id) REFERENCES auth.users(id) not valid;

alter table "public"."products" validate constraint "products_seller_id_fkey";

alter table "public"."products" add constraint "products_store_id_fkey" FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE not valid;

alter table "public"."products" validate constraint "products_store_id_fkey";

alter table "public"."shopping_sessions" add constraint "shopping_sessions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."shopping_sessions" validate constraint "shopping_sessions_user_id_fkey";

alter table "public"."shopping_sessions" add constraint "unique_active_session" UNIQUE using index "unique_active_session";

alter table "public"."stores" add constraint "stores_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."stores" validate constraint "stores_user_id_fkey";

alter table "public"."stores" add constraint "unique_store_url" UNIQUE using index "unique_store_url";

alter table "public"."user_preferences" add constraint "user_preferences_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_preferences" validate constraint "user_preferences_user_id_fkey";

alter table "public"."user_preferences" add constraint "user_preferences_user_id_key" UNIQUE using index "user_preferences_user_id_key";

alter table "public"."users" add constraint "users_email_key" UNIQUE using index "users_email_key";

alter table "public"."users" add constraint "users_firebase_uid_key" UNIQUE using index "users_firebase_uid_key";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.calculate_affiliate_commission()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    referrer_id uuid;
    commission numeric;
BEGIN
    -- Get the referrer's affiliate account ID for the order's user
    SELECT ar.referrer_id INTO referrer_id
    FROM affiliate_referrals ar
    WHERE ar.referred_user_id = NEW.user_id
    AND ar.status = 'active'
    LIMIT 1;

    -- If there's a referrer, calculate and record commission
    IF referrer_id IS NOT NULL THEN
        -- Calculate commission using the current commission rate
        SELECT (NEW.total * affiliate_settings.commission_rate / 100) INTO commission
        FROM affiliate_settings
        LIMIT 1;

        -- Insert the commission record
        INSERT INTO affiliate_commissions (
            affiliate_id,
            order_id,
            amount,
            status
        ) VALUES (
            referrer_id,
            NEW.id,
            commission,
            'pending'
        );

        -- Update the affiliate's total earnings
        UPDATE affiliate_accounts
        SET earnings = earnings + commission
        WHERE id = referrer_id;
    END IF;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.clear_user_cart_after_order(p_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_session_id uuid;
  v_items_deleted integer;
BEGIN
  -- Get active shopping session
  SELECT id INTO v_session_id
  FROM shopping_sessions 
  WHERE user_id = p_user_id AND status = 'active'
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_session_id IS NOT NULL THEN
    -- Delete cart items and count deleted rows
    DELETE FROM cart_items_new 
    WHERE session_id = v_session_id AND is_saved_for_later = false;
    
    GET DIAGNOSTICS v_items_deleted = ROW_COUNT;
    
    -- Update shopping session timestamp
    UPDATE shopping_sessions 
    SET updated_at = now()
    WHERE id = v_session_id;
    
    RAISE NOTICE 'Cleared % cart items for user: %', v_items_deleted, p_user_id;
    RETURN true;
  ELSE
    RAISE NOTICE 'No active shopping session found for user: %', p_user_id;
    RETURN false;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to clear cart for user %: %', p_user_id, SQLERRM;
    RETURN false;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_order_with_items(p_user_id uuid, p_total numeric, p_delivery_fee numeric DEFAULT 0, p_delivery_fee_paid boolean DEFAULT true, p_payment_option text DEFAULT 'full'::text, p_delivery_name text DEFAULT NULL::text, p_delivery_phone text DEFAULT NULL::text, p_delivery_address text DEFAULT NULL::text, p_payment_method text DEFAULT 'flutterwave'::text, p_cart_items jsonb DEFAULT '[]'::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_order_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_quantity integer;
  v_price numeric;
  v_variant_id uuid;
  v_selected_color text;
  v_selected_size text;
  v_item_count integer;
BEGIN
  -- Input validation
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User ID is required';
  END IF;
  
  IF p_total IS NULL OR p_total <= 0 THEN
    RAISE EXCEPTION 'Total amount must be greater than 0, got: %', p_total;
  END IF;
  
  IF p_delivery_name IS NULL OR trim(p_delivery_name) = '' THEN
    RAISE EXCEPTION 'Delivery name is required';
  END IF;
  
  IF p_delivery_phone IS NULL OR trim(p_delivery_phone) = '' THEN
    RAISE EXCEPTION 'Delivery phone is required';
  END IF;
  
  IF p_delivery_address IS NULL OR trim(p_delivery_address) = '' THEN
    RAISE EXCEPTION 'Delivery address is required';
  END IF;

  -- Validate payment option
  IF p_payment_option NOT IN ('full', 'partial') THEN
    RAISE EXCEPTION 'Payment option must be either "full" or "partial", got: %', p_payment_option;
  END IF;

  -- Validate cart items
  v_item_count := jsonb_array_length(p_cart_items);
  IF v_item_count = 0 THEN
    RAISE EXCEPTION 'Cart items are required to create an order';
  END IF;

  -- Log order creation attempt
  RAISE NOTICE 'Creating order for user % with total % and % items', p_user_id, p_total, v_item_count;

  -- Create the order
  INSERT INTO orders (
    user_id,
    total,
    delivery_fee,
    delivery_fee_paid,
    payment_option,
    status,
    delivery_name,
    delivery_phone,
    delivery_address,
    payment_method,
    payment_ref,
    created_at
  ) VALUES (
    p_user_id,
    p_total,
    COALESCE(p_delivery_fee, 0),
    COALESCE(p_delivery_fee_paid, true),
    COALESCE(p_payment_option, 'full'),
    'pending',
    trim(p_delivery_name),
    trim(p_delivery_phone),
    trim(p_delivery_address),
    COALESCE(p_payment_method, 'flutterwave'),
    'pending',
    now()
  ) RETURNING id INTO v_order_id;

  -- Insert order items
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_cart_items)
  LOOP
    -- Extract and validate item data
    BEGIN
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := (v_item->>'quantity')::integer;
      v_price := (v_item->>'price')::numeric;
      
      -- Handle variant data with proper null checks
      v_variant_id := CASE 
        WHEN v_item->>'variant_id' IS NULL OR 
             v_item->>'variant_id' = 'null' OR 
             v_item->>'variant_id' = '' OR
             v_item->>'variant_id' = 'undefined'
        THEN NULL 
        ELSE (v_item->>'variant_id')::uuid 
      END;
      
      v_selected_color := CASE 
        WHEN v_item->>'selected_color' IS NULL OR 
             v_item->>'selected_color' = 'null' OR 
             v_item->>'selected_color' = '' OR
             v_item->>'selected_color' = 'undefined'
        THEN NULL 
        ELSE v_item->>'selected_color' 
      END;
      
      v_selected_size := CASE 
        WHEN v_item->>'selected_size' IS NULL OR 
             v_item->>'selected_size' = 'null' OR 
             v_item->>'selected_size' = '' OR
             v_item->>'selected_size' = 'undefined'
        THEN NULL 
        ELSE v_item->>'selected_size' 
      END;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE EXCEPTION 'Invalid item data in cart: %', v_item::text;
    END;

    -- Validate extracted data
    IF v_product_id IS NULL THEN
      RAISE EXCEPTION 'Product ID is required for order item: %', v_item::text;
    END IF;
    
    IF v_quantity IS NULL OR v_quantity <= 0 THEN
      RAISE EXCEPTION 'Valid quantity is required for order item, got: %', v_quantity;
    END IF;
    
    IF v_price IS NULL OR v_price <= 0 THEN
      RAISE EXCEPTION 'Valid price is required for order item, got: %', v_price;
    END IF;

    -- Verify product exists
    IF NOT EXISTS (SELECT 1 FROM products WHERE id = v_product_id) THEN
      RAISE EXCEPTION 'Product not found: %', v_product_id;
    END IF;

    -- Insert order item
    INSERT INTO order_items (
      order_id,
      product_id,
      quantity,
      price,
      variant_id,
      selected_color,
      selected_size,
      created_at
    ) VALUES (
      v_order_id,
      v_product_id,
      v_quantity,
      v_price,
      v_variant_id,
      v_selected_color,
      v_selected_size,
      now()
    );

    RAISE NOTICE 'Added item to order: product_id=%, quantity=%, price=%', v_product_id, v_quantity, v_price;
  END LOOP;

  -- Log successful order creation
  RAISE NOTICE 'Order created successfully: % with % items', v_order_id, v_item_count;

  RETURN v_order_id;

EXCEPTION
  WHEN OTHERS THEN
    -- Log the error details
    RAISE EXCEPTION 'Failed to create order for user %: %', p_user_id, SQLERRM;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_unique_referral_code(user_id uuid)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  base_code text;
  final_code text;
  counter integer := 0;
BEGIN
  -- Generate base code from user_id
  base_code := substr(replace(user_id::text, '-', ''), 1, 8);
  final_code := upper(base_code);
  
  -- Keep trying until we find a unique code
  WHILE EXISTS (
    SELECT 1 FROM affiliate_accounts WHERE referral_code = final_code
  ) LOOP
    counter := counter + 1;
    final_code := upper(base_code || counter::text);
  END LOOP;
  
  RETURN final_code;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_total_users()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
DECLARE
  total_count integer;
BEGIN
  SELECT COUNT(*) INTO total_count FROM auth.users;
  RETURN total_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_count()
 RETURNS bigint
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT COUNT(*)::bigint FROM auth.users;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_admin_on_order()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  -- Just log the order for now
  RAISE NOTICE 'New order received: %', NEW.id;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.track_page_view(p_session_id text, p_user_id uuid DEFAULT NULL::uuid, p_page_path text DEFAULT '/'::text, p_user_agent text DEFAULT ''::text, p_ip_address text DEFAULT ''::text, p_referrer text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  INSERT INTO analytics_page_views (
    session_id, user_id, page_path, user_agent, ip_address, referrer
  )
  VALUES (
    p_session_id, p_user_id, p_page_path, p_user_agent, p_ip_address, p_referrer
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_affiliate_referral_count()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Increment referral count
    UPDATE affiliate_accounts
    SET referral_count = referral_count + 1
    WHERE id = NEW.referrer_id;
  ELSIF TG_OP = 'DELETE' THEN
    -- Decrement referral count
    UPDATE affiliate_accounts
    SET referral_count = GREATEST(0, referral_count - 1)
    WHERE id = OLD.referrer_id;
  END IF;
  RETURN NULL;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_daily_stats()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  today_date date := CURRENT_DATE;
  unique_visitors_count integer := 0;
  page_views_count integer := 0;
  new_users_count integer := 0;
  orders_count integer := 0;
  revenue_amount numeric := 0;
BEGIN
  -- Calculate unique visitors for today
  SELECT COUNT(DISTINCT session_id)
  INTO unique_visitors_count
  FROM analytics_page_views
  WHERE DATE(created_at) = today_date;

  -- Calculate total page views for today
  SELECT COUNT(*)
  INTO page_views_count
  FROM analytics_page_views
  WHERE DATE(created_at) = today_date;

  -- Calculate new users for today (users who signed up today)
  SELECT COUNT(*)
  INTO new_users_count
  FROM auth.users
  WHERE DATE(created_at) = today_date;

  -- Calculate orders count for today
  SELECT COUNT(*)
  INTO orders_count
  FROM orders
  WHERE DATE(created_at) = today_date;

  -- Calculate revenue for today
  SELECT COALESCE(SUM(total), 0)
  INTO revenue_amount
  FROM orders
  WHERE DATE(created_at) = today_date
    AND status != 'cancelled';

  -- Insert or update the daily stats
  INSERT INTO analytics_daily_stats (
    date,
    unique_visitors,
    page_views,
    new_users,
    orders_count,
    revenue
  )
  VALUES (
    today_date,
    unique_visitors_count,
    page_views_count,
    new_users_count,
    orders_count,
    revenue_amount
  )
  ON CONFLICT (date)
  DO UPDATE SET
    unique_visitors = EXCLUDED.unique_visitors,
    page_views = EXCLUDED.page_views,
    new_users = EXCLUDED.new_users,
    orders_count = EXCLUDED.orders_count,
    revenue = EXCLUDED.revenue,
    updated_at = now();
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_order_payment_status(p_order_id uuid, p_payment_ref text, p_status text DEFAULT 'completed'::text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_order_exists boolean;
  v_current_status text;
BEGIN
  -- Check if order exists and get current status
  SELECT EXISTS(SELECT 1 FROM orders WHERE id = p_order_id), 
         (SELECT status FROM orders WHERE id = p_order_id LIMIT 1)
  INTO v_order_exists, v_current_status;
  
  IF NOT v_order_exists THEN
    RAISE EXCEPTION 'Order not found: %', p_order_id;
  END IF;

  -- Only update if order is still pending
  IF v_current_status != 'pending' THEN
    RAISE NOTICE 'Order % is already in status: %', p_order_id, v_current_status;
    RETURN false;
  END IF;

  -- Update order with payment information
  UPDATE orders 
  SET 
    payment_ref = p_payment_ref,
    status = p_status
  WHERE id = p_order_id AND status = 'pending';

  -- Check if update was successful
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Failed to update order payment status for order: %', p_order_id;
  END IF;

  RAISE NOTICE 'Payment status updated for order: % to status: %', p_order_id, p_status;
  RETURN true;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to update payment status for order %: %', p_order_id, SQLERRM;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_order_total()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  UPDATE orders
  SET total = (
    SELECT COALESCE(SUM(quantity * price), 0)
    FROM order_items
    WHERE order_id = NEW.order_id
  )
  WHERE id = NEW.order_id;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_product_price()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.discount_active = true AND NEW.discount_price IS NOT NULL THEN
    NEW.price = NEW.discount_price;
  ELSE
    NEW.price = NEW.original_price;
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_variant_data()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  -- If variant_id is provided, validate that all variant fields are consistent
  IF NEW.variant_id IS NOT NULL THEN
    -- Check that color and size are also provided
    IF NEW.selected_color IS NULL OR NEW.selected_size IS NULL THEN
      RAISE EXCEPTION 'When variant_id is provided, selected_color and selected_size must also be provided';
    END IF;
    
    -- Verify that the variant exists and matches the selected color and size
    IF NOT EXISTS (
      SELECT 1 FROM product_variants
      WHERE id = NEW.variant_id
      AND color = NEW.selected_color
      AND size = NEW.selected_size
    ) THEN
      RAISE EXCEPTION 'Invalid variant data: variant does not match selected color and size';
    END IF;
  ELSE
    -- If no variant_id, ensure color and size are also null
    IF NEW.selected_color IS NOT NULL OR NEW.selected_size IS NOT NULL THEN
      RAISE EXCEPTION 'When variant_id is null, selected_color and selected_size must also be null';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$function$
;

grant delete on table "public"."advertisements" to "anon";

grant insert on table "public"."advertisements" to "anon";

grant references on table "public"."advertisements" to "anon";

grant select on table "public"."advertisements" to "anon";

grant trigger on table "public"."advertisements" to "anon";

grant truncate on table "public"."advertisements" to "anon";

grant update on table "public"."advertisements" to "anon";

grant delete on table "public"."advertisements" to "authenticated";

grant insert on table "public"."advertisements" to "authenticated";

grant references on table "public"."advertisements" to "authenticated";

grant select on table "public"."advertisements" to "authenticated";

grant trigger on table "public"."advertisements" to "authenticated";

grant truncate on table "public"."advertisements" to "authenticated";

grant update on table "public"."advertisements" to "authenticated";

grant delete on table "public"."advertisements" to "service_role";

grant insert on table "public"."advertisements" to "service_role";

grant references on table "public"."advertisements" to "service_role";

grant select on table "public"."advertisements" to "service_role";

grant trigger on table "public"."advertisements" to "service_role";

grant truncate on table "public"."advertisements" to "service_role";

grant update on table "public"."advertisements" to "service_role";

grant delete on table "public"."affiliate_accounts" to "anon";

grant insert on table "public"."affiliate_accounts" to "anon";

grant references on table "public"."affiliate_accounts" to "anon";

grant select on table "public"."affiliate_accounts" to "anon";

grant trigger on table "public"."affiliate_accounts" to "anon";

grant truncate on table "public"."affiliate_accounts" to "anon";

grant update on table "public"."affiliate_accounts" to "anon";

grant delete on table "public"."affiliate_accounts" to "authenticated";

grant insert on table "public"."affiliate_accounts" to "authenticated";

grant references on table "public"."affiliate_accounts" to "authenticated";

grant select on table "public"."affiliate_accounts" to "authenticated";

grant trigger on table "public"."affiliate_accounts" to "authenticated";

grant truncate on table "public"."affiliate_accounts" to "authenticated";

grant update on table "public"."affiliate_accounts" to "authenticated";

grant delete on table "public"."affiliate_accounts" to "service_role";

grant insert on table "public"."affiliate_accounts" to "service_role";

grant references on table "public"."affiliate_accounts" to "service_role";

grant select on table "public"."affiliate_accounts" to "service_role";

grant trigger on table "public"."affiliate_accounts" to "service_role";

grant truncate on table "public"."affiliate_accounts" to "service_role";

grant update on table "public"."affiliate_accounts" to "service_role";

grant delete on table "public"."affiliate_commissions" to "anon";

grant insert on table "public"."affiliate_commissions" to "anon";

grant references on table "public"."affiliate_commissions" to "anon";

grant select on table "public"."affiliate_commissions" to "anon";

grant trigger on table "public"."affiliate_commissions" to "anon";

grant truncate on table "public"."affiliate_commissions" to "anon";

grant update on table "public"."affiliate_commissions" to "anon";

grant delete on table "public"."affiliate_commissions" to "authenticated";

grant insert on table "public"."affiliate_commissions" to "authenticated";

grant references on table "public"."affiliate_commissions" to "authenticated";

grant select on table "public"."affiliate_commissions" to "authenticated";

grant trigger on table "public"."affiliate_commissions" to "authenticated";

grant truncate on table "public"."affiliate_commissions" to "authenticated";

grant update on table "public"."affiliate_commissions" to "authenticated";

grant delete on table "public"."affiliate_commissions" to "service_role";

grant insert on table "public"."affiliate_commissions" to "service_role";

grant references on table "public"."affiliate_commissions" to "service_role";

grant select on table "public"."affiliate_commissions" to "service_role";

grant trigger on table "public"."affiliate_commissions" to "service_role";

grant truncate on table "public"."affiliate_commissions" to "service_role";

grant update on table "public"."affiliate_commissions" to "service_role";

grant delete on table "public"."affiliate_referrals" to "anon";

grant insert on table "public"."affiliate_referrals" to "anon";

grant references on table "public"."affiliate_referrals" to "anon";

grant select on table "public"."affiliate_referrals" to "anon";

grant trigger on table "public"."affiliate_referrals" to "anon";

grant truncate on table "public"."affiliate_referrals" to "anon";

grant update on table "public"."affiliate_referrals" to "anon";

grant delete on table "public"."affiliate_referrals" to "authenticated";

grant insert on table "public"."affiliate_referrals" to "authenticated";

grant references on table "public"."affiliate_referrals" to "authenticated";

grant select on table "public"."affiliate_referrals" to "authenticated";

grant trigger on table "public"."affiliate_referrals" to "authenticated";

grant truncate on table "public"."affiliate_referrals" to "authenticated";

grant update on table "public"."affiliate_referrals" to "authenticated";

grant delete on table "public"."affiliate_referrals" to "service_role";

grant insert on table "public"."affiliate_referrals" to "service_role";

grant references on table "public"."affiliate_referrals" to "service_role";

grant select on table "public"."affiliate_referrals" to "service_role";

grant trigger on table "public"."affiliate_referrals" to "service_role";

grant truncate on table "public"."affiliate_referrals" to "service_role";

grant update on table "public"."affiliate_referrals" to "service_role";

grant delete on table "public"."affiliate_settings" to "anon";

grant insert on table "public"."affiliate_settings" to "anon";

grant references on table "public"."affiliate_settings" to "anon";

grant select on table "public"."affiliate_settings" to "anon";

grant trigger on table "public"."affiliate_settings" to "anon";

grant truncate on table "public"."affiliate_settings" to "anon";

grant update on table "public"."affiliate_settings" to "anon";

grant delete on table "public"."affiliate_settings" to "authenticated";

grant insert on table "public"."affiliate_settings" to "authenticated";

grant references on table "public"."affiliate_settings" to "authenticated";

grant select on table "public"."affiliate_settings" to "authenticated";

grant trigger on table "public"."affiliate_settings" to "authenticated";

grant truncate on table "public"."affiliate_settings" to "authenticated";

grant update on table "public"."affiliate_settings" to "authenticated";

grant delete on table "public"."affiliate_settings" to "service_role";

grant insert on table "public"."affiliate_settings" to "service_role";

grant references on table "public"."affiliate_settings" to "service_role";

grant select on table "public"."affiliate_settings" to "service_role";

grant trigger on table "public"."affiliate_settings" to "service_role";

grant truncate on table "public"."affiliate_settings" to "service_role";

grant update on table "public"."affiliate_settings" to "service_role";

grant delete on table "public"."analytics_daily_stats" to "anon";

grant insert on table "public"."analytics_daily_stats" to "anon";

grant references on table "public"."analytics_daily_stats" to "anon";

grant select on table "public"."analytics_daily_stats" to "anon";

grant trigger on table "public"."analytics_daily_stats" to "anon";

grant truncate on table "public"."analytics_daily_stats" to "anon";

grant update on table "public"."analytics_daily_stats" to "anon";

grant delete on table "public"."analytics_daily_stats" to "authenticated";

grant insert on table "public"."analytics_daily_stats" to "authenticated";

grant references on table "public"."analytics_daily_stats" to "authenticated";

grant select on table "public"."analytics_daily_stats" to "authenticated";

grant trigger on table "public"."analytics_daily_stats" to "authenticated";

grant truncate on table "public"."analytics_daily_stats" to "authenticated";

grant update on table "public"."analytics_daily_stats" to "authenticated";

grant delete on table "public"."analytics_daily_stats" to "service_role";

grant insert on table "public"."analytics_daily_stats" to "service_role";

grant references on table "public"."analytics_daily_stats" to "service_role";

grant select on table "public"."analytics_daily_stats" to "service_role";

grant trigger on table "public"."analytics_daily_stats" to "service_role";

grant truncate on table "public"."analytics_daily_stats" to "service_role";

grant update on table "public"."analytics_daily_stats" to "service_role";

grant delete on table "public"."analytics_page_views" to "anon";

grant insert on table "public"."analytics_page_views" to "anon";

grant references on table "public"."analytics_page_views" to "anon";

grant select on table "public"."analytics_page_views" to "anon";

grant trigger on table "public"."analytics_page_views" to "anon";

grant truncate on table "public"."analytics_page_views" to "anon";

grant update on table "public"."analytics_page_views" to "anon";

grant delete on table "public"."analytics_page_views" to "authenticated";

grant insert on table "public"."analytics_page_views" to "authenticated";

grant references on table "public"."analytics_page_views" to "authenticated";

grant select on table "public"."analytics_page_views" to "authenticated";

grant trigger on table "public"."analytics_page_views" to "authenticated";

grant truncate on table "public"."analytics_page_views" to "authenticated";

grant update on table "public"."analytics_page_views" to "authenticated";

grant delete on table "public"."analytics_page_views" to "service_role";

grant insert on table "public"."analytics_page_views" to "service_role";

grant references on table "public"."analytics_page_views" to "service_role";

grant select on table "public"."analytics_page_views" to "service_role";

grant trigger on table "public"."analytics_page_views" to "service_role";

grant truncate on table "public"."analytics_page_views" to "service_role";

grant update on table "public"."analytics_page_views" to "service_role";

grant delete on table "public"."app_settings" to "anon";

grant insert on table "public"."app_settings" to "anon";

grant references on table "public"."app_settings" to "anon";

grant select on table "public"."app_settings" to "anon";

grant trigger on table "public"."app_settings" to "anon";

grant truncate on table "public"."app_settings" to "anon";

grant update on table "public"."app_settings" to "anon";

grant delete on table "public"."app_settings" to "authenticated";

grant insert on table "public"."app_settings" to "authenticated";

grant references on table "public"."app_settings" to "authenticated";

grant select on table "public"."app_settings" to "authenticated";

grant trigger on table "public"."app_settings" to "authenticated";

grant truncate on table "public"."app_settings" to "authenticated";

grant update on table "public"."app_settings" to "authenticated";

grant delete on table "public"."app_settings" to "service_role";

grant insert on table "public"."app_settings" to "service_role";

grant references on table "public"."app_settings" to "service_role";

grant select on table "public"."app_settings" to "service_role";

grant trigger on table "public"."app_settings" to "service_role";

grant truncate on table "public"."app_settings" to "service_role";

grant update on table "public"."app_settings" to "service_role";

grant delete on table "public"."cart_items" to "anon";

grant insert on table "public"."cart_items" to "anon";

grant references on table "public"."cart_items" to "anon";

grant select on table "public"."cart_items" to "anon";

grant trigger on table "public"."cart_items" to "anon";

grant truncate on table "public"."cart_items" to "anon";

grant update on table "public"."cart_items" to "anon";

grant delete on table "public"."cart_items" to "authenticated";

grant insert on table "public"."cart_items" to "authenticated";

grant references on table "public"."cart_items" to "authenticated";

grant select on table "public"."cart_items" to "authenticated";

grant trigger on table "public"."cart_items" to "authenticated";

grant truncate on table "public"."cart_items" to "authenticated";

grant update on table "public"."cart_items" to "authenticated";

grant delete on table "public"."cart_items" to "service_role";

grant insert on table "public"."cart_items" to "service_role";

grant references on table "public"."cart_items" to "service_role";

grant select on table "public"."cart_items" to "service_role";

grant trigger on table "public"."cart_items" to "service_role";

grant truncate on table "public"."cart_items" to "service_role";

grant update on table "public"."cart_items" to "service_role";

grant delete on table "public"."cart_items_new" to "anon";

grant insert on table "public"."cart_items_new" to "anon";

grant references on table "public"."cart_items_new" to "anon";

grant select on table "public"."cart_items_new" to "anon";

grant trigger on table "public"."cart_items_new" to "anon";

grant truncate on table "public"."cart_items_new" to "anon";

grant update on table "public"."cart_items_new" to "anon";

grant delete on table "public"."cart_items_new" to "authenticated";

grant insert on table "public"."cart_items_new" to "authenticated";

grant references on table "public"."cart_items_new" to "authenticated";

grant select on table "public"."cart_items_new" to "authenticated";

grant trigger on table "public"."cart_items_new" to "authenticated";

grant truncate on table "public"."cart_items_new" to "authenticated";

grant update on table "public"."cart_items_new" to "authenticated";

grant delete on table "public"."cart_items_new" to "service_role";

grant insert on table "public"."cart_items_new" to "service_role";

grant references on table "public"."cart_items_new" to "service_role";

grant select on table "public"."cart_items_new" to "service_role";

grant trigger on table "public"."cart_items_new" to "service_role";

grant truncate on table "public"."cart_items_new" to "service_role";

grant update on table "public"."cart_items_new" to "service_role";

grant delete on table "public"."order_items" to "anon";

grant insert on table "public"."order_items" to "anon";

grant references on table "public"."order_items" to "anon";

grant select on table "public"."order_items" to "anon";

grant trigger on table "public"."order_items" to "anon";

grant truncate on table "public"."order_items" to "anon";

grant update on table "public"."order_items" to "anon";

grant delete on table "public"."order_items" to "authenticated";

grant insert on table "public"."order_items" to "authenticated";

grant references on table "public"."order_items" to "authenticated";

grant select on table "public"."order_items" to "authenticated";

grant trigger on table "public"."order_items" to "authenticated";

grant truncate on table "public"."order_items" to "authenticated";

grant update on table "public"."order_items" to "authenticated";

grant delete on table "public"."order_items" to "service_role";

grant insert on table "public"."order_items" to "service_role";

grant references on table "public"."order_items" to "service_role";

grant select on table "public"."order_items" to "service_role";

grant trigger on table "public"."order_items" to "service_role";

grant truncate on table "public"."order_items" to "service_role";

grant update on table "public"."order_items" to "service_role";

grant delete on table "public"."orders" to "anon";

grant insert on table "public"."orders" to "anon";

grant references on table "public"."orders" to "anon";

grant select on table "public"."orders" to "anon";

grant trigger on table "public"."orders" to "anon";

grant truncate on table "public"."orders" to "anon";

grant update on table "public"."orders" to "anon";

grant delete on table "public"."orders" to "authenticated";

grant insert on table "public"."orders" to "authenticated";

grant references on table "public"."orders" to "authenticated";

grant select on table "public"."orders" to "authenticated";

grant trigger on table "public"."orders" to "authenticated";

grant truncate on table "public"."orders" to "authenticated";

grant update on table "public"."orders" to "authenticated";

grant delete on table "public"."orders" to "service_role";

grant insert on table "public"."orders" to "service_role";

grant references on table "public"."orders" to "service_role";

grant select on table "public"."orders" to "service_role";

grant trigger on table "public"."orders" to "service_role";

grant truncate on table "public"."orders" to "service_role";

grant update on table "public"."orders" to "service_role";

grant delete on table "public"."product_images" to "anon";

grant insert on table "public"."product_images" to "anon";

grant references on table "public"."product_images" to "anon";

grant select on table "public"."product_images" to "anon";

grant trigger on table "public"."product_images" to "anon";

grant truncate on table "public"."product_images" to "anon";

grant update on table "public"."product_images" to "anon";

grant delete on table "public"."product_images" to "authenticated";

grant insert on table "public"."product_images" to "authenticated";

grant references on table "public"."product_images" to "authenticated";

grant select on table "public"."product_images" to "authenticated";

grant trigger on table "public"."product_images" to "authenticated";

grant truncate on table "public"."product_images" to "authenticated";

grant update on table "public"."product_images" to "authenticated";

grant delete on table "public"."product_images" to "service_role";

grant insert on table "public"."product_images" to "service_role";

grant references on table "public"."product_images" to "service_role";

grant select on table "public"."product_images" to "service_role";

grant trigger on table "public"."product_images" to "service_role";

grant truncate on table "public"."product_images" to "service_role";

grant update on table "public"."product_images" to "service_role";

grant delete on table "public"."product_ratings" to "anon";

grant insert on table "public"."product_ratings" to "anon";

grant references on table "public"."product_ratings" to "anon";

grant select on table "public"."product_ratings" to "anon";

grant trigger on table "public"."product_ratings" to "anon";

grant truncate on table "public"."product_ratings" to "anon";

grant update on table "public"."product_ratings" to "anon";

grant delete on table "public"."product_ratings" to "authenticated";

grant insert on table "public"."product_ratings" to "authenticated";

grant references on table "public"."product_ratings" to "authenticated";

grant select on table "public"."product_ratings" to "authenticated";

grant trigger on table "public"."product_ratings" to "authenticated";

grant truncate on table "public"."product_ratings" to "authenticated";

grant update on table "public"."product_ratings" to "authenticated";

grant delete on table "public"."product_ratings" to "service_role";

grant insert on table "public"."product_ratings" to "service_role";

grant references on table "public"."product_ratings" to "service_role";

grant select on table "public"."product_ratings" to "service_role";

grant trigger on table "public"."product_ratings" to "service_role";

grant truncate on table "public"."product_ratings" to "service_role";

grant update on table "public"."product_ratings" to "service_role";

grant delete on table "public"."product_variants" to "anon";

grant insert on table "public"."product_variants" to "anon";

grant references on table "public"."product_variants" to "anon";

grant select on table "public"."product_variants" to "anon";

grant trigger on table "public"."product_variants" to "anon";

grant truncate on table "public"."product_variants" to "anon";

grant update on table "public"."product_variants" to "anon";

grant delete on table "public"."product_variants" to "authenticated";

grant insert on table "public"."product_variants" to "authenticated";

grant references on table "public"."product_variants" to "authenticated";

grant select on table "public"."product_variants" to "authenticated";

grant trigger on table "public"."product_variants" to "authenticated";

grant truncate on table "public"."product_variants" to "authenticated";

grant update on table "public"."product_variants" to "authenticated";

grant delete on table "public"."product_variants" to "service_role";

grant insert on table "public"."product_variants" to "service_role";

grant references on table "public"."product_variants" to "service_role";

grant select on table "public"."product_variants" to "service_role";

grant trigger on table "public"."product_variants" to "service_role";

grant truncate on table "public"."product_variants" to "service_role";

grant update on table "public"."product_variants" to "service_role";

grant delete on table "public"."products" to "anon";

grant insert on table "public"."products" to "anon";

grant references on table "public"."products" to "anon";

grant select on table "public"."products" to "anon";

grant trigger on table "public"."products" to "anon";

grant truncate on table "public"."products" to "anon";

grant update on table "public"."products" to "anon";

grant delete on table "public"."products" to "authenticated";

grant insert on table "public"."products" to "authenticated";

grant references on table "public"."products" to "authenticated";

grant select on table "public"."products" to "authenticated";

grant trigger on table "public"."products" to "authenticated";

grant truncate on table "public"."products" to "authenticated";

grant update on table "public"."products" to "authenticated";

grant delete on table "public"."products" to "service_role";

grant insert on table "public"."products" to "service_role";

grant references on table "public"."products" to "service_role";

grant select on table "public"."products" to "service_role";

grant trigger on table "public"."products" to "service_role";

grant truncate on table "public"."products" to "service_role";

grant update on table "public"."products" to "service_role";

grant delete on table "public"."shopping_sessions" to "anon";

grant insert on table "public"."shopping_sessions" to "anon";

grant references on table "public"."shopping_sessions" to "anon";

grant select on table "public"."shopping_sessions" to "anon";

grant trigger on table "public"."shopping_sessions" to "anon";

grant truncate on table "public"."shopping_sessions" to "anon";

grant update on table "public"."shopping_sessions" to "anon";

grant delete on table "public"."shopping_sessions" to "authenticated";

grant insert on table "public"."shopping_sessions" to "authenticated";

grant references on table "public"."shopping_sessions" to "authenticated";

grant select on table "public"."shopping_sessions" to "authenticated";

grant trigger on table "public"."shopping_sessions" to "authenticated";

grant truncate on table "public"."shopping_sessions" to "authenticated";

grant update on table "public"."shopping_sessions" to "authenticated";

grant delete on table "public"."shopping_sessions" to "service_role";

grant insert on table "public"."shopping_sessions" to "service_role";

grant references on table "public"."shopping_sessions" to "service_role";

grant select on table "public"."shopping_sessions" to "service_role";

grant trigger on table "public"."shopping_sessions" to "service_role";

grant truncate on table "public"."shopping_sessions" to "service_role";

grant update on table "public"."shopping_sessions" to "service_role";

grant delete on table "public"."stores" to "anon";

grant insert on table "public"."stores" to "anon";

grant references on table "public"."stores" to "anon";

grant select on table "public"."stores" to "anon";

grant trigger on table "public"."stores" to "anon";

grant truncate on table "public"."stores" to "anon";

grant update on table "public"."stores" to "anon";

grant delete on table "public"."stores" to "authenticated";

grant insert on table "public"."stores" to "authenticated";

grant references on table "public"."stores" to "authenticated";

grant select on table "public"."stores" to "authenticated";

grant trigger on table "public"."stores" to "authenticated";

grant truncate on table "public"."stores" to "authenticated";

grant update on table "public"."stores" to "authenticated";

grant delete on table "public"."stores" to "service_role";

grant insert on table "public"."stores" to "service_role";

grant references on table "public"."stores" to "service_role";

grant select on table "public"."stores" to "service_role";

grant trigger on table "public"."stores" to "service_role";

grant truncate on table "public"."stores" to "service_role";

grant update on table "public"."stores" to "service_role";

grant delete on table "public"."user_preferences" to "anon";

grant insert on table "public"."user_preferences" to "anon";

grant references on table "public"."user_preferences" to "anon";

grant select on table "public"."user_preferences" to "anon";

grant trigger on table "public"."user_preferences" to "anon";

grant truncate on table "public"."user_preferences" to "anon";

grant update on table "public"."user_preferences" to "anon";

grant delete on table "public"."user_preferences" to "authenticated";

grant insert on table "public"."user_preferences" to "authenticated";

grant references on table "public"."user_preferences" to "authenticated";

grant select on table "public"."user_preferences" to "authenticated";

grant trigger on table "public"."user_preferences" to "authenticated";

grant truncate on table "public"."user_preferences" to "authenticated";

grant update on table "public"."user_preferences" to "authenticated";

grant delete on table "public"."user_preferences" to "service_role";

grant insert on table "public"."user_preferences" to "service_role";

grant references on table "public"."user_preferences" to "service_role";

grant select on table "public"."user_preferences" to "service_role";

grant trigger on table "public"."user_preferences" to "service_role";

grant truncate on table "public"."user_preferences" to "service_role";

grant update on table "public"."user_preferences" to "service_role";

grant delete on table "public"."users" to "anon";

grant insert on table "public"."users" to "anon";

grant references on table "public"."users" to "anon";

grant select on table "public"."users" to "anon";

grant trigger on table "public"."users" to "anon";

grant truncate on table "public"."users" to "anon";

grant update on table "public"."users" to "anon";

grant delete on table "public"."users" to "authenticated";

grant insert on table "public"."users" to "authenticated";

grant references on table "public"."users" to "authenticated";

grant select on table "public"."users" to "authenticated";

grant trigger on table "public"."users" to "authenticated";

grant truncate on table "public"."users" to "authenticated";

grant update on table "public"."users" to "authenticated";

grant delete on table "public"."users" to "service_role";

grant insert on table "public"."users" to "service_role";

grant references on table "public"."users" to "service_role";

grant select on table "public"."users" to "service_role";

grant trigger on table "public"."users" to "service_role";

grant truncate on table "public"."users" to "service_role";

grant update on table "public"."users" to "service_role";

create policy "Anyone can view advertisements"
on "public"."advertisements"
as permissive
for select
to public
using (true);


create policy "Only admins can manage advertisements"
on "public"."advertisements"
as permissive
for all
to authenticated
using (((auth.jwt() ->> 'email'::text) = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])))
with check (((auth.jwt() ->> 'email'::text) = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])));


create policy "Users can create their own affiliate account"
on "public"."affiliate_accounts"
as permissive
for insert
to authenticated
with check ((auth.uid() = user_id));


create policy "Users can update their own affiliate account"
on "public"."affiliate_accounts"
as permissive
for update
to authenticated
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));


create policy "Users can view their own affiliate account"
on "public"."affiliate_accounts"
as permissive
for select
to authenticated
using ((auth.uid() = user_id));


create policy "Users can view their commissions"
on "public"."affiliate_commissions"
as permissive
for select
to authenticated
using ((affiliate_id IN ( SELECT affiliate_accounts.id
   FROM affiliate_accounts
  WHERE (affiliate_accounts.user_id = auth.uid()))));


create policy "Users can view their referrals"
on "public"."affiliate_referrals"
as permissive
for select
to authenticated
using ((referrer_id IN ( SELECT affiliate_accounts.id
   FROM affiliate_accounts
  WHERE (affiliate_accounts.user_id = auth.uid()))));


create policy "Anyone can view affiliate settings"
on "public"."affiliate_settings"
as permissive
for select
to public
using (true);


create policy "Only admins can manage affiliate settings"
on "public"."affiliate_settings"
as permissive
for all
to authenticated
using (((auth.jwt() ->> 'email'::text) = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])))
with check (((auth.jwt() ->> 'email'::text) = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])));


create policy "Only admins can manage daily stats"
on "public"."analytics_daily_stats"
as permissive
for all
to authenticated
using ((auth.uid() IN ( SELECT users.id
   FROM auth.users
  WHERE ((users.email)::text = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])))))
with check ((auth.uid() IN ( SELECT users.id
   FROM auth.users
  WHERE ((users.email)::text = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])))));


create policy "Only admins can view daily stats"
on "public"."analytics_daily_stats"
as permissive
for select
to authenticated
using ((auth.uid() IN ( SELECT users.id
   FROM auth.users
  WHERE ((users.email)::text = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])))));


create policy "Anyone can insert page views"
on "public"."analytics_page_views"
as permissive
for insert
to public
with check (true);


create policy "Only admins can view page views"
on "public"."analytics_page_views"
as permissive
for select
to authenticated
using ((auth.uid() IN ( SELECT users.id
   FROM auth.users
  WHERE ((users.email)::text = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])))));


create policy "Anyone can view app settings"
on "public"."app_settings"
as permissive
for select
to public
using (true);


create policy "Only admins can manage app settings"
on "public"."app_settings"
as permissive
for all
to authenticated
using (((auth.jwt() ->> 'email'::text) = 'paulelite606@gmail.com'::text))
with check (((auth.jwt() ->> 'email'::text) = 'paulelite606@gmail.com'::text));


create policy "Users can manage their own cart items"
on "public"."cart_items"
as permissive
for all
to authenticated
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));


create policy "Users can view their own cart items"
on "public"."cart_items"
as permissive
for select
to authenticated
using ((auth.uid() = user_id));


create policy "Users can delete their own cart items"
on "public"."cart_items_new"
as permissive
for delete
to authenticated
using ((EXISTS ( SELECT 1
   FROM shopping_sessions
  WHERE ((shopping_sessions.id = cart_items_new.session_id) AND (shopping_sessions.user_id = auth.uid())))));


create policy "Users can insert their own cart items"
on "public"."cart_items_new"
as permissive
for insert
to authenticated
with check ((EXISTS ( SELECT 1
   FROM shopping_sessions
  WHERE ((shopping_sessions.id = cart_items_new.session_id) AND (shopping_sessions.user_id = auth.uid()) AND (shopping_sessions.status = 'active'::text)))));


create policy "Users can update their own cart items"
on "public"."cart_items_new"
as permissive
for update
to authenticated
using ((EXISTS ( SELECT 1
   FROM shopping_sessions
  WHERE ((shopping_sessions.id = cart_items_new.session_id) AND (shopping_sessions.user_id = auth.uid()) AND (shopping_sessions.status = 'active'::text)))))
with check ((EXISTS ( SELECT 1
   FROM shopping_sessions
  WHERE ((shopping_sessions.id = cart_items_new.session_id) AND (shopping_sessions.user_id = auth.uid()) AND (shopping_sessions.status = 'active'::text)))));


create policy "Users can view their own cart items"
on "public"."cart_items_new"
as permissive
for select
to authenticated
using ((EXISTS ( SELECT 1
   FROM shopping_sessions
  WHERE ((shopping_sessions.id = cart_items_new.session_id) AND (shopping_sessions.user_id = auth.uid())))));


create policy "Users can create their own order items"
on "public"."order_items"
as permissive
for insert
to authenticated
with check ((EXISTS ( SELECT 1
   FROM orders
  WHERE ((orders.id = order_items.order_id) AND (orders.user_id = auth.uid())))));


create policy "Users can view their own order items"
on "public"."order_items"
as permissive
for select
to authenticated
using ((EXISTS ( SELECT 1
   FROM orders
  WHERE ((orders.id = order_items.order_id) AND (orders.user_id = auth.uid())))));


create policy "Users can create their own orders"
on "public"."orders"
as permissive
for insert
to authenticated
with check ((auth.uid() = user_id));


create policy "Users can view their own orders"
on "public"."orders"
as permissive
for select
to authenticated
using ((auth.uid() = user_id));


create policy "Anyone can view product images"
on "public"."product_images"
as permissive
for select
to public
using (true);


create policy "Only admins can manage product images"
on "public"."product_images"
as permissive
for all
to authenticated
using (((auth.jwt() ->> 'email'::text) = 'paulelite606@gmail.com'::text))
with check (((auth.jwt() ->> 'email'::text) = 'paulelite606@gmail.com'::text));


create policy "Users can create their own ratings"
on "public"."product_ratings"
as permissive
for insert
to authenticated
with check ((auth.uid() = user_id));


create policy "Users can delete their own ratings"
on "public"."product_ratings"
as permissive
for delete
to authenticated
using ((auth.uid() = user_id));


create policy "Users can update their own ratings"
on "public"."product_ratings"
as permissive
for update
to authenticated
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));


create policy "Users can view all product ratings"
on "public"."product_ratings"
as permissive
for select
to public
using (true);


create policy "Anyone can view product variants"
on "public"."product_variants"
as permissive
for select
to public
using (true);


create policy "Only admins can manage product variants"
on "public"."product_variants"
as permissive
for all
to authenticated
using (((auth.jwt() ->> 'email'::text) = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])))
with check (((auth.jwt() ->> 'email'::text) = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])));


create policy "Anyone can view products"
on "public"."products"
as permissive
for select
to public
using (true);


create policy "Only admins can insert products"
on "public"."products"
as permissive
for insert
to authenticated
with check (((auth.jwt() ->> 'email'::text) = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])));


create policy "Only admins can manage products"
on "public"."products"
as permissive
for all
to authenticated
using (((auth.jwt() ->> 'email'::text) = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])))
with check (((auth.jwt() ->> 'email'::text) = ANY (ARRAY['paulelite606@gmail.com'::text, 'obajeufedo2@gmail.com'::text])));


create policy "Users can create their own shopping sessions"
on "public"."shopping_sessions"
as permissive
for insert
to authenticated
with check ((auth.uid() = user_id));


create policy "Users can delete their own shopping sessions"
on "public"."shopping_sessions"
as permissive
for delete
to authenticated
using ((auth.uid() = user_id));


create policy "Users can update their own shopping sessions"
on "public"."shopping_sessions"
as permissive
for update
to authenticated
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));


create policy "Users can view their own shopping sessions"
on "public"."shopping_sessions"
as permissive
for select
to authenticated
using ((auth.uid() = user_id));


create policy "Users can create their own stores"
on "public"."stores"
as permissive
for insert
to authenticated
with check ((auth.uid() = user_id));


create policy "Users can delete their own stores"
on "public"."stores"
as permissive
for delete
to authenticated
using ((auth.uid() = user_id));


create policy "Users can update their own stores"
on "public"."stores"
as permissive
for update
to authenticated
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));


create policy "Users can view all stores"
on "public"."stores"
as permissive
for select
to public
using (true);


create policy "Users can insert their own preferences"
on "public"."user_preferences"
as permissive
for insert
to authenticated
with check ((auth.uid() = user_id));


create policy "Users can update their own preferences"
on "public"."user_preferences"
as permissive
for update
to authenticated
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));


create policy "Users can view their own preferences"
on "public"."user_preferences"
as permissive
for select
to authenticated
using ((auth.uid() = user_id));


create policy "Users can update their own data"
on "public"."users"
as permissive
for update
to authenticated
using ((firebase_uid = ((current_setting('request.jwt.claims'::text))::json ->> 'sub'::text)))
with check ((firebase_uid = ((current_setting('request.jwt.claims'::text))::json ->> 'sub'::text)));


create policy "Users can view their own data"
on "public"."users"
as permissive
for select
to public
using (true);


CREATE TRIGGER update_referral_count_trigger AFTER INSERT OR DELETE ON public.affiliate_referrals FOR EACH ROW EXECUTE FUNCTION update_affiliate_referral_count();

CREATE TRIGGER update_cart_items_new_updated_at BEFORE UPDATE ON public.cart_items_new FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER validate_cart_variant_data BEFORE INSERT OR UPDATE ON public.cart_items_new FOR EACH ROW EXECUTE FUNCTION validate_variant_data();

CREATE TRIGGER update_order_total_trigger AFTER INSERT OR DELETE OR UPDATE ON public.order_items FOR EACH ROW EXECUTE FUNCTION update_order_total();

CREATE TRIGGER validate_order_variant_data BEFORE INSERT OR UPDATE ON public.order_items FOR EACH ROW EXECUTE FUNCTION validate_variant_data();

CREATE TRIGGER calculate_commission_trigger AFTER INSERT ON public.orders FOR EACH ROW EXECUTE FUNCTION calculate_affiliate_commission();

CREATE TRIGGER order_notification_trigger AFTER INSERT ON public.orders FOR EACH ROW EXECUTE FUNCTION notify_admin_on_order();

CREATE TRIGGER update_product_price_trigger BEFORE INSERT OR UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION update_product_price();

CREATE TRIGGER update_shopping_sessions_updated_at BEFORE UPDATE ON public.shopping_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON public.user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


