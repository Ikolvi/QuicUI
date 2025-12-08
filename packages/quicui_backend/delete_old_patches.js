const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  'https://pcaxvanjhtfaeimflgfk.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjYXh2YW5qaHRmYWVpbWZsZ2ZrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMjcxNDIzMiwiZXhwIjoyMDQ4MjkwMjMyfQ.F8oJ4c2zfJ9Wai2XC6v9EEZDzJAZx8tgNwg_GY1b5Og'
);

async function main() {
  // List all patches for this app
  const { data: patches, error } = await supabase
    .from('patches')
    .select('*')
    .eq('app_id', 'com.example.quicuiProductionTest')
    .order('created_at', { ascending: false });
    
  if (error) {
    console.error('Error:', error);
    return;
  }
  
  console.log(`Found ${patches.length} patches:`);
  patches.forEach(p => {
    console.log(`  - ID: ${p.patch_id}, v${p.from_version} -> v${p.version}, ${p.platform}/${p.architecture}, ${new Date(p.created_at).toISOString()}`);
  });
  
  // Delete old v3.0.46 and v3.0.47 patches
  const toDelete = patches.filter(p => p.version === '3.0.46' || p.version === '3.0.47');
  
  for (const patch of toDelete) {
    console.log(`\nDeleting patch ${patch.patch_id} (v${patch.version})...`);
    
    // Delete from storage
    const { error: storageError } = await supabase.storage
      .from('patches')
      .remove([`${patch.patch_id}.vmcode.xz`]);
      
    if (storageError) {
      console.error('  Storage delete error:', storageError);
    } else {
      console.log('  ✅ Deleted from storage');
    }
    
    // Delete from database
    const { error: dbError } = await supabase
      .from('patches')
      .delete()
      .eq('patch_id', patch.patch_id);
      
    if (dbError) {
      console.error('  DB delete error:', dbError);
    } else {
      console.log('  ✅ Deleted from database');
    }
  }
  
  console.log('\n✅ Cleanup complete!');
}

main();
