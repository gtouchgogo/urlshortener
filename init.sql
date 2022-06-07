CREATE TABLE public.url_shortener
(
  id          SERIAL PRIMARY KEY,
  url_raw     text,
  url_md5     text,
  url_b62     text,
  create_time timestamptz DEFAULT (now())::timestamp(3),
  is_valid    boolean     DEFAULT true

);
COMMENT ON COLUMN url_shortener.id IS '自增id';
COMMENT ON COLUMN url_shortener.url_raw IS '原始的url';
COMMENT ON COLUMN url_shortener.url_md5 IS '原始url的md5';
COMMENT ON COLUMN url_shortener.url_b62 IS '短链（只包含短链路径）';
COMMENT ON COLUMN url_shortener.create_time IS '短链创建时间，默认当前';
COMMENT ON COLUMN url_shortener.is_valid IS '链接目前是否可用，默认可用';


CREATE INDEX url_shortener_md5_idx ON public.url_shortener USING btree (url_md5);
CREATE INDEX url_shortener_b62_idx ON public.url_shortener USING btree (url_b62);
CREATE UNIQUE INDEX url_shortener_b62_raw_idx ON public.url_shortener USING btree(url_b62, url_raw);



CREATE SEQUENCE public.url_shortener_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;
ALTER SEQUENCE public.url_shortener_id_seq OWNED BY public.url_shortener.id;
ALTER TABLE ONLY public.url_shortener
  ALTER COLUMN id SET DEFAULT nextval('public.url_shortener_id_seq'::regclass);

