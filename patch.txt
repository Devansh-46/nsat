Future<void> removeFinderExtendedAttributes(
  FileSystemEntity projectDirectory,
  ProcessUtils processUtils,
  Logger logger,
) async {
  await processUtils.exitsHappy(<String>[
    'xattr',
    '-r',
    '-d',
    'com.apple.provenance',
    projectDirectory.path,
  ]);
  final bool success = await processUtils.exitsHappy(<String>[
    'xattr',
    '-r',
    '-d',
    'com.apple.FinderInfo',
    projectDirectory.path,
  ]);
  if (!success) {
    logger.printTrace('Failed to remove xattr com.apple.FinderInfo from ${projectDirectory.path}');
  }
}
