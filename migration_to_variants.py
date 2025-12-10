"""
Django Migration Script: Current System → Optimal Variant-Based System

This script provides a step-by-step migration from your current implementation
to the optimal scalable e-commerce schema with ProductVariants.

IMPORTANT: Run this in a development environment first!
"""

from django.db import transaction
from django.core.management.base import BaseCommand
from shop.models import Product, ProductAttributeValue, Attribute, NewAttributeValue
import logging

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Migrate existing products to variant-based system'
    
    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be migrated without making changes',
        )
        parser.add_argument(
            '--batch-size',
            type=int,
            default=100,
            help='Number of products to process in each batch',
        )
    
    def handle(self, *args, **options):
        dry_run = options['dry_run']
        batch_size = options['batch_size']
        
        if dry_run:
            self.stdout.write(
                self.style.WARNING('DRY RUN MODE - No changes will be made')
            )
        
        self.migrate_products_to_variants(dry_run, batch_size)
    
    @transaction.atomic
    def migrate_products_to_variants(self, dry_run=False, batch_size=100):
        """
        Main migration function that converts products to variant-based system
        """
        self.stdout.write("Starting migration to variant-based system...")
        
        # Step 1: Add new models (would be done via Django migrations)
        self.stdout.write("Step 1: Ensure new models exist (ProductVariant, VariantAttribute)")
        if not self._check_new_models_exist():
            self.stdout.write(
                self.style.ERROR(
                    "New models not found. Please run Django migrations first to add:"
                    "\n- ProductVariant"
                    "\n- VariantAttribute"
                )
            )
            return
        
        # Step 2: Analyze current data
        stats = self._analyze_current_data()
        self._print_analysis(stats)
        
        # Step 3: Migrate products in batches
        if not dry_run:
            self._migrate_products_batch(batch_size)
        else:
            self._simulate_migration(batch_size)
        
        self.stdout.write(
            self.style.SUCCESS("Migration completed successfully!")
        )
    
    def _check_new_models_exist(self):
        """Check if new models have been added via migrations"""
        try:
            from shop.models import ProductVariant, VariantAttribute
            return True
        except ImportError:
            return False
    
    def _analyze_current_data(self):
        """Analyze current database state"""
        stats = {
            'total_products': Product.objects.count(),
            'active_products': Product.objects.filter(is_active=True).count(),
            'products_with_attributes': Product.objects.filter(
                attribute_values__isnull=False
            ).distinct().count(),
            'total_attributes': Attribute.objects.count(),
            'total_attribute_values': NewAttributeValue.objects.count(),
            'products_with_stock': Product.objects.filter(
                stock_quantity__gt=0
            ).count(),
        }
        return stats
    
    def _print_analysis(self, stats):
        """Print analysis of current data"""
        self.stdout.write("\n" + "="*50)
        self.stdout.write("CURRENT DATABASE ANALYSIS")
        self.stdout.write("="*50)
        self.stdout.write(f"Total Products: {stats['total_products']}")
        self.stdout.write(f"Active Products: {stats['active_products']}")
        self.stdout.write(f"Products with Attributes: {stats['products_with_attributes']}")
        self.stdout.write(f"Total Attributes: {stats['total_attributes']}")
        self.stdout.write(f"Total Attribute Values: {stats['total_attribute_values']}")
        self.stdout.write(f"Products with Stock: {stats['products_with_stock']}")
        self.stdout.write("="*50 + "\n")
    
    def _migrate_products_batch(self, batch_size):
        """Migrate products in batches to avoid memory issues"""
        from shop.models import ProductVariant, VariantAttribute
        
        total_products = Product.objects.count()
        processed = 0
        
        self.stdout.write(f"Migrating {total_products} products in batches of {batch_size}...")
        
        # Process products in batches
        for start in range(0, total_products, batch_size):
            end = min(start + batch_size, total_products)
            
            products_batch = Product.objects.all()[start:end]
            
            with transaction.atomic():
                for product in products_batch:
                    self._migrate_single_product(product, ProductVariant, VariantAttribute)
                    processed += 1
                    
                    if processed % 10 == 0:
                        self.stdout.write(f"Processed {processed}/{total_products} products...")
        
        self.stdout.write(f"Successfully migrated {processed} products!")
    
    def _migrate_single_product(self, product, ProductVariant, VariantAttribute):
        """Migrate a single product to variant-based system"""
        
        # Check if variant already exists (avoid duplicates)
        existing_variant = ProductVariant.objects.filter(
            product=product,
            is_default=True
        ).first()
        
        if existing_variant:
            logger.info(f"Variant already exists for product {product.id}, skipping...")
            return existing_variant
        
        # Create default variant
        variant = ProductVariant.objects.create(
            product=product,
            sku=self._generate_sku(product),
            name=f"{product.name} - Default",
            price=product.price_toman or 0,
            stock_quantity=product.stock_quantity,
            weight=product.weight,
            dimensions=product.dimensions,
            is_active=product.is_active,
            is_default=True
        )
        
        # Migrate attributes
        self._migrate_product_attributes(product, variant, VariantAttribute)
        
        logger.info(f"Created variant {variant.sku} for product {product.name}")
        return variant
    
    def _generate_sku(self, product):
        """Generate SKU for variant"""
        if product.sku:
            return product.sku
        
        # Generate from product name and ID
        base_sku = product.name.upper().replace(' ', '-')[:10]
        return f"{base_sku}-{product.id}"
    
    def _migrate_product_attributes(self, product, variant, VariantAttribute):
        """Migrate product attributes to variant attributes"""
        
        migrated_count = 0
        
        for product_attr in product.attribute_values.all():
            if product_attr.attribute_value:
                # Create VariantAttribute if it doesn't exist
                variant_attr, created = VariantAttribute.objects.get_or_create(
                    variant=variant,
                    attribute_value=product_attr.attribute_value
                )
                
                if created:
                    migrated_count += 1
                    logger.debug(
                        f"Created VariantAttribute: {variant.sku} -> "
                        f"{product_attr.attribute_value}"
                    )
        
        if migrated_count > 0:
            logger.info(f"Migrated {migrated_count} attributes for variant {variant.sku}")
    
    def _simulate_migration(self, batch_size):
        """Simulate migration without making changes (dry run)"""
        total_products = Product.objects.count()
        
        self.stdout.write(f"\nSIMULATION: Would migrate {total_products} products")
        self.stdout.write("-" * 40)
        
        # Analyze some sample products
        sample_products = Product.objects.all()[:5]
        
        for product in sample_products:
            self.stdout.write(f"\nProduct: {product.name} (ID: {product.id})")
            self.stdout.write(f"  Would create variant with SKU: {self._generate_sku(product)}")
            self.stdout.write(f"  Price: {product.price_toman}")
            self.stdout.write(f"  Stock: {product.stock_quantity}")
            
            # Show attributes that would be migrated
            attributes = product.attribute_values.filter(
                attribute_value__isnull=False
            )
            if attributes.exists():
                self.stdout.write("  Attributes to migrate:")
                for attr in attributes:
                    self.stdout.write(f"    - {attr.attribute_value}")
            else:
                self.stdout.write("  No attributes to migrate")
        
        self.stdout.write(f"\n... and {total_products - 5} more products")


# Additional utility functions for post-migration cleanup

def cleanup_legacy_data():
    """
    Clean up legacy data after successful migration
    WARNING: This will permanently delete old data!
    """
    pass  # Implement based on your specific needs


def verify_migration():
    """
    Verify that migration completed successfully
    """
    from shop.models import ProductVariant, VariantAttribute
    
    stats = {
        'products_without_variants': Product.objects.filter(
            variants__isnull=True
        ).count(),
        'variants_without_attributes': ProductVariant.objects.filter(
            variant_attributes__isnull=True
        ).count(),
        'total_variants_created': ProductVariant.objects.count(),
        'total_variant_attributes': VariantAttribute.objects.count(),
    }
    
    print("MIGRATION VERIFICATION")
    print("=" * 30)
    for key, value in stats.items():
        print(f"{key}: {value}")
    
    if stats['products_without_variants'] == 0:
        print("✅ All products have variants")
    else:
        print(f"❌ {stats['products_without_variants']} products missing variants")
    
    return stats


# Django Management Command Integration
"""
To use this migration script:

1. Add new models to your shop/models.py:
   - ProductVariant
   - VariantAttribute

2. Create and run Django migrations:
   python manage.py makemigrations shop
   python manage.py migrate

3. Run the migration script:
   # Dry run first
   python manage.py migrate_to_variants --dry-run
   
   # Actual migration
   python manage.py migrate_to_variants

4. Verify migration:
   python manage.py shell
   >>> from migration_to_variants import verify_migration
   >>> verify_migration()
"""
