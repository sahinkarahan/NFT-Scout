import Foundation

// MARK: - String Extension for Collection ID Conversion
extension String {
    /// CoinGecko ID'sini OpenSea slug'ına dönüştürür.
    /// - Returns: Dönüştürülmüş OpenSea slug'ı
    func toOpenSeaSlug() -> String {
        // Önceden tanımlanmış kesin eşleştirmeler - Doğrulanmış eşleştirmeler
        let predefinedMappings: [String: String] = [
            // Tire işaretleri tamamen kaldırılanlar
            "cryptopunks": "cryptopunks",
            "infinex-patrons": "infinex-patrons",
            "boredapeyachtclub": "boredapeyachtclub",
            "pudgy-penguins": "pudgypenguins",
            "autoglyphs": "autoglyphs",
            "mutant-ape-yacht-club": "mutant-ape-yacht-club",
            "chromie-squiggle-by-snowfro": "chromie-squiggle-by-snowfro",
            "milady-maker": "milady",
            "mad-lads": "mad-lads-on-polygon",
            "doodles-official": "doodles-official",
            "fidenza-by-tyler-hobbs": "fidenza-by-tyler-hobbs",
            "creepz-genesis": "genesis-creepz",
            "azuki": "azuki",
            "lilpudgys": "lilpudgys",
            "mocaverse": "mocaverse",
            "bitcoin-puppets": "bitcoin-puppet",
            "nodemonkes": "nodemonkes",
            "quantum-cats": "quantum-cats-nfts",
            "veefriends": "veefriends",
            "meebits": "meebits",
            "runestone": "runestone-37",
            "the-band-bears": "the-band-bears",
            "onchainmonkey-ocm-genesis": "onchainmonkey",
            "ringers-by-dmitri-cherniak": "ringers-by-dmitri-cherniak",
            "claynosaurz": "claynosaurz-sol",
            "the-captainz": "memelandcaptainz",
            "otherdeed-expanded": "otherdeed-expanded",
            "synclub-s-snbnb-early-adopters": "synclub-s-snbnb-early-adopters-1",
            "otherdeed-for-otherside": "otherdeed",
            "ordinal-maxi-biz-omb": "ordinal-maxi-biz-7",
            "bitmap": "bitmap",
            "lifinity-flares": "lifinity-flares",
            "solana-monkey-business": "solana-monkey-business",
            "kanpai-pandas": "kanpai-pandas",
            "onchainmonkey": "onchainmonkey",
            "degen-fat-cats": "degenfatcats",
            "mfers": "mfers",
            "parallel-avatars": "parallel-avatars",
            "redacted-remilio-babies": "remilio-babies",
            "sappy-seals": "sappy-seals",
            "ggsg-galactic-geckos": "galactic-gecko-space-garage",
            "degods": "degods-solana",
            "wealthy-hypio-babies": "hypio",
            "terraforms-by-mathcastles": "terraforms",
            "tomorrowland-a-letter-from-the-universe": "the-symbol-sol",
            "bitcoin-frogs": "bitcoin-frogs-nft",
            "bad-kids": "bad-kids-alley-official",
            "cyberkongz": "cyberkongz-vx"
        ]
        
        // Önceden tanımlanmış eşleştirmelere bakıyoruz
        if let mappedSlug = predefinedMappings[self] {
            return mappedSlug
        }
        
        // Tanımlanmamış ID'ler için akıllı dönüşüm algoritması
        
        // 1. Deseni "by-[creator]" şeklinde olan kısımları çıkar
        let withoutCreator = self.replacingOccurrences(of: "-by-[a-zA-Z0-9-]+", with: "", options: .regularExpression)
        
        // 2. Genel kuralları uygula
        
        // Belirli koleksiyon tipleri için kurallar
        if withoutCreator.contains("lil-") || withoutCreator.contains("-lil") {
            // "lil" içeren koleksiyonlarda genellikle tire kaldırılır
            return withoutCreator.replacingOccurrences(of: "-", with: "")
        }
        
        if withoutCreator.contains("ape") {
            // "ape" içeren koleksiyonlarda genellikle tire kaldırılır (BAYC, MAYC vb.)
            return withoutCreator.replacingOccurrences(of: "-", with: "")
        }
        
        if withoutCreator.contains("punk") {
            // "punk" içeren koleksiyonlarda genellikle tire kaldırılır
            return withoutCreator.replacingOccurrences(of: "-", with: "")
        }
        
        // Popüler koleksiyon markalarında tire kaldırılır
        let popularBrands = ["azuki", "doodles", "meebits", "moonbirds", "pudgy", "nounsdao"]
        for brand in popularBrands {
            if withoutCreator.contains(brand) {
                return withoutCreator.replacingOccurrences(of: "-", with: "")
            }
        }
        
        // 3. Genel olarak tireleri koru (büyük koleksiyonlarda genellikle tire korunur)
        if withoutCreator.starts(with: "the-") || withoutCreator.contains("-the-") {
            // "the" içeren koleksiyonlarda genellikle tire korunur
            return withoutCreator
        }
        
        // 4. 2 veya 3 kelimeden oluşan isimler için kurallar
        let components = withoutCreator.components(separatedBy: "-")
        if components.count <= 3 {
            // Bazı büyük popüler koleksiyonlarda tire kaldırılır
            return withoutCreator.replacingOccurrences(of: "-", with: "")
        }
        
        // 5. Daha uzun isimler içinse genellikle tire korunur
        return withoutCreator
    }
}

// MARK: - ID Eşleştirme Yardımcısı
struct CollectionIDMapper {
    /// CoinGecko ID'sinden OpenSea slug'ına dönüştürme yapar
    /// - Parameter coinGeckoID: CoinGecko'dan alınan koleksiyon ID'si
    /// - Returns: OpenSea'de kullanılabilecek slug
    static func mapToOpenSeaSlug(_ coinGeckoID: String) -> String {
        return coinGeckoID.toOpenSeaSlug()
    }
    
    /// OpenSea slug'ından CoinGecko ID'sine geri dönüştürme yapar (gerekirse)
    /// - Parameter openSeaSlug: OpenSea'den alınan slug
    /// - Returns: CoinGecko'da kullanılabilecek ID
    static func mapToCoinGeckoID(_ openSeaSlug: String) -> String? {
        // Ters eşleştirme için özel bir metot (İhtiyaç olursa kullanılır)
        // Şimdilik basit örnek
        if openSeaSlug == "boredapeyachtclub" {
            return "bored-ape-yacht-club"
        }
        
        return nil // Şimdilik tam tersine dönüşüm desteği sınırlı
    }
    
    /// Bilinen tüm eşleştirmeleri döndürür
    static var allMappings: [String: String] {
        // Bir string'in toOpenSeaSlug metodundaki dictionary'yi direkt alabilecek bir yol yok
        // Bu nedenle sabit bir liste döndürüyoruz
        return [
            "cryptopunks": "cryptopunks",
            "bored-ape-yacht-club": "boredapeyachtclub",
            "pudgy-penguins": "pudgypenguins",
            "autoglyphs": "autoglyphs",
            "mutant-ape-yacht-club": "mutantapeyachtclub",
            "chromie-squiggle-by-snowfro": "chromie-squiggle",
            "mad-lads": "mad-lads",
            "fidenza-by-tyler-hobbs": "fidenza"
            // Daha fazla eşleştirme eklenebilir
        ]
    }
} 
